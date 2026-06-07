import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createAdminClient } from "../_shared/adminClient.ts";
import { getRequestUser } from "../_shared/auth.ts";
import { handleOptions } from "../_shared/cors.ts";
import { EdgeFunctionError, toEdgeFunctionError } from "../_shared/errors.ts";
import { errorResponse, jsonResponse } from "../_shared/response.ts";
import { optionalString, requireString } from "../_shared/validators.ts";

type VerificationResult = {
  verified: boolean;
  status: "active" | "expired" | "revoked" | "pending";
  expiresAt: string | null;
  rawResponse: Record<string, unknown>;
  errorCode?: string;
};

const GOOGLE_PLAY_PACKAGE_NAME = "com.fuelarena.fuel_arena";

function normalizeProvider(provider: string) {
  const normalized = provider.toLowerCase().replaceAll("-", "_").replaceAll(" ", "_");
  if (["google_play", "google", "android"].includes(normalized)) return "google_play";
  if (["app_store", "apple", "ios"].includes(normalized)) return "app_store";
  if (["mock", "dev_mock"].includes(normalized)) return "mock";
  throw new EdgeFunctionError("지원하지 않는 결제 provider입니다.", 400, "unsupported_provider");
}

function base64UrlEncode(value: Uint8Array | string) {
  const bytes = typeof value === "string" ? new TextEncoder().encode(value) : value;
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

function base64UrlDecodeJson(value: string) {
  const normalized = value.replaceAll("-", "+").replaceAll("_", "/");
  const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, "=");
  const decoded = atob(padded);
  const bytes = new Uint8Array([...decoded].map((char) => char.charCodeAt(0)));
  return JSON.parse(new TextDecoder().decode(bytes)) as Record<string, unknown>;
}

function pemToArrayBuffer(pem: string) {
  const base64 = pem
    .replace(/-----BEGIN [^-]+-----/g, "")
    .replace(/-----END [^-]+-----/g, "")
    .replace(/\s+/g, "");
  const binary = atob(base64);
  return Uint8Array.from([...binary].map((char) => char.charCodeAt(0))).buffer;
}

async function sha256Hex(value: string) {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

function requireSecret(name: string) {
  const value = Deno.env.get(name);
  if (!value) {
    throw new EdgeFunctionError(`${name} secret is not configured.`, 500, "purchase_secret_missing");
  }
  return value;
}

async function signJwt(
  header: Record<string, unknown>,
  payload: Record<string, unknown>,
  key: CryptoKey,
  algorithm: AlgorithmIdentifier | RsaPssParams | EcdsaParams,
) {
  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(payload));
  const signingInput = `${encodedHeader}.${encodedPayload}`;
  const signature = await crypto.subtle.sign(
    algorithm,
    key,
    new TextEncoder().encode(signingInput),
  );
  return `${signingInput}.${base64UrlEncode(new Uint8Array(signature))}`;
}

async function fetchJson(url: string, init: RequestInit, errorCode: string) {
  const response = await fetch(url, init);
  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new EdgeFunctionError(
      `provider verification failed: ${response.status}`,
      502,
      errorCode,
    );
  }
  return body as Record<string, unknown>;
}

function firstLineItem(response: Record<string, unknown>) {
  const lineItems = response.lineItems;
  return Array.isArray(lineItems) && lineItems.length > 0
    ? (lineItems[0] as Record<string, unknown>)
    : {};
}

async function verifyGooglePlayPurchase(params: {
  productId: string;
  purchaseToken: string;
  packageName: string;
}) {
  const serviceAccountJson = requireSecret("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON");
  const parsed = JSON.parse(serviceAccountJson) as Record<string, unknown>;
  const clientEmail = `${parsed.client_email ?? ""}`;
  const privateKey = `${parsed.private_key ?? ""}`;
  if (!clientEmail || !privateKey.includes("BEGIN PRIVATE KEY")) {
    throw new EdgeFunctionError("Google Play service account secret is invalid.", 500, "purchase_secret_invalid");
  }
  const now = Math.floor(Date.now() / 1000);
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKey),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const assertion = await signJwt(
    { alg: "RS256", typ: "JWT" },
    {
      iss: clientEmail,
      scope: "https://www.googleapis.com/auth/androidpublisher",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    },
    key,
    { name: "RSASSA-PKCS1-v1_5" },
  );
  const tokenResponse = await fetchJson(
    "https://oauth2.googleapis.com/token",
    {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion,
      }),
    },
    "google_oauth_failed",
  );
  const accessToken = `${tokenResponse.access_token ?? ""}`;
  if (!accessToken) {
    throw new EdgeFunctionError("Google access token was not issued.", 502, "google_oauth_failed");
  }

  const encodedPackage = encodeURIComponent(params.packageName);
  const encodedToken = encodeURIComponent(params.purchaseToken);
  const subscriptionUrl =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodedPackage}/purchases/subscriptionsv2/tokens/${encodedToken}`;
  const subscriptionResponse = await fetch(subscriptionUrl, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (subscriptionResponse.ok) {
    const subscription = await subscriptionResponse.json() as Record<string, unknown>;
    const lineItem = firstLineItem(subscription);
    const productId = `${lineItem.productId ?? ""}`;
    const state = `${subscription.subscriptionState ?? "SUBSCRIPTION_STATE_PENDING"}`;
    const expiresAt = `${lineItem.expiryTime ?? ""}` || null;
    const verified = productId == params.productId &&
      ["SUBSCRIPTION_STATE_ACTIVE", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD"].includes(state);
    return {
      verified,
      status: verified ? "active" : state.includes("EXPIRED") ? "expired" : "pending",
      expiresAt,
      rawResponse: {
        provider: "google_play",
        subscriptionState: state,
        productId,
        latestOrderId: subscription.latestOrderId,
      },
      errorCode: verified ? undefined : "google_subscription_inactive",
    } satisfies VerificationResult;
  }

  const productUrl =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodedPackage}/purchases/products/${encodeURIComponent(params.productId)}/tokens/${encodedToken}`;
  const product = await fetchJson(
    productUrl,
    { headers: { Authorization: `Bearer ${accessToken}` } },
    "google_product_lookup_failed",
  );
  const purchaseState = Number(product.purchaseState ?? 1);
  const verified = purchaseState === 0;
  return {
    verified,
    status: verified ? "active" : "revoked",
    expiresAt: null,
    rawResponse: {
      provider: "google_play",
      packageName: params.packageName,
      productId: params.productId,
      purchaseState,
      orderId: product.orderId,
    },
    errorCode: verified ? undefined : "google_purchase_inactive",
  } satisfies VerificationResult;
}

async function verifyAppStorePurchase(params: {
  productId: string;
  purchaseToken: string;
  transactionId: string;
}) {
  const issuerId = requireSecret("APP_STORE_CONNECT_ISSUER_ID");
  const keyId = requireSecret("APP_STORE_CONNECT_KEY_ID");
  const privateKey = requireSecret("APP_STORE_CONNECT_PRIVATE_KEY");
  const bundleId = requireSecret("APP_STORE_BUNDLE_ID");
  if (!issuerId || !keyId || !privateKey.includes("BEGIN PRIVATE KEY")) {
    throw new EdgeFunctionError("App Store Connect secrets are invalid.", 500, "purchase_secret_invalid");
  }
  if (!/^[A-Za-z0-9]+(?:[.-][A-Za-z0-9]+)+$/.test(bundleId)) {
    throw new EdgeFunctionError("APP_STORE_BUNDLE_ID is invalid.", 500, "purchase_secret_invalid");
  }
  const now = Math.floor(Date.now() / 1000);
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKey),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  const token = await signJwt(
    { alg: "ES256", kid: keyId, typ: "JWT" },
    {
      iss: issuerId,
      iat: now,
      exp: now + 1800,
      aud: "appstoreconnect-v1",
      bid: bundleId,
    },
    key,
    { name: "ECDSA", hash: "SHA-256" },
  );
  const environment = (Deno.env.get("APP_STORE_ENV") ?? "production").toLowerCase();
  const host = environment === "sandbox"
    ? "https://api.storekit-sandbox.itunes.apple.com"
    : "https://api.storekit.itunes.apple.com";
  const transaction = await fetchJson(
    `${host}/inApps/v1/transactions/${encodeURIComponent(params.transactionId)}`,
    { headers: { Authorization: `Bearer ${token}` } },
    "app_store_transaction_lookup_failed",
  );
  const signedTransactionInfo = `${transaction.signedTransactionInfo ?? ""}`;
  if (!signedTransactionInfo.includes(".")) {
    throw new EdgeFunctionError("App Store transaction response is invalid.", 502, "app_store_response_invalid");
  }
  const transactionPayload = base64UrlDecodeJson(signedTransactionInfo.split(".")[1]);
  const productId = `${transactionPayload.productId ?? ""}`;
  const expiresDateMs = Number(transactionPayload.expiresDate ?? 0);
  const revocationDate = Number(transactionPayload.revocationDate ?? 0);
  const expiresAt = expiresDateMs > 0 ? new Date(expiresDateMs).toISOString() : null;
  const active = revocationDate <= 0 && (expiresDateMs <= 0 || expiresDateMs > Date.now());
  const verified = productId === params.productId && active;
  return {
    verified,
    status: verified ? "active" : revocationDate > 0 ? "revoked" : "expired",
    expiresAt,
    rawResponse: {
      provider: "app_store",
      transactionId: params.transactionId,
      originalTransactionId: transactionPayload.originalTransactionId,
      productId,
      environment: transactionPayload.environment,
    },
    errorCode: verified ? undefined : "app_store_transaction_inactive",
  } satisfies VerificationResult;
}

async function verifyMockPurchase(params: {
  productId: string;
  purchaseToken: string;
}) {
  const allowMock = Deno.env.get("ALLOW_MOCK_PURCHASE_VERIFICATION") === "true";
  const appEnv = (Deno.env.get("APP_ENV") ?? "production").toLowerCase();
  if (!allowMock || appEnv === "production") {
    throw new EdgeFunctionError("mock purchase verification is disabled.", 403, "mock_purchase_disabled");
  }
  const verified = params.purchaseToken.startsWith("mock_") && params.purchaseToken.length >= 16;
  return {
    verified,
    status: verified ? "active" : "revoked",
    expiresAt: verified ? new Date(Date.now() + 31 * 24 * 60 * 60 * 1000).toISOString() : null,
    rawResponse: {
      provider: "mock",
      productId: params.productId,
    },
    errorCode: verified ? undefined : "mock_token_invalid",
  } satisfies VerificationResult;
}

function planStatusFor(result: VerificationResult) {
  if (result.verified && result.status === "active") return "active";
  if (result.status === "expired") return "expired";
  if (result.status === "revoked") return "cancelled";
  return "pending_review";
}

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;
  if (req.method !== "POST") return errorResponse("POST 요청만 지원합니다.", 405, "method_not_allowed");

  try {
    const client = createAdminClient();
    const user = await getRequestUser(req, client);
    if (!user) {
      throw new EdgeFunctionError("로그인이 필요합니다.", 401, "unauthorized");
    }

    const body = await req.json().catch(() => ({}));
    const provider = normalizeProvider(requireString(body.provider, "provider"));
    const productId = requireString(body.productId, "productId");
    const purchaseToken = requireString(body.purchaseToken, "purchaseToken");
    const transactionId = requireString(body.transactionId, "transactionId");
    const planId = optionalString(body.planId);

    const { data: plan, error: planError } = await client
      .from("subscription_plans")
      .select("id,product_id")
      .eq("product_id", productId)
      .maybeSingle();
    if (planError) {
      throw new EdgeFunctionError(planError.message, 500, "plan_lookup_failed");
    }
    const resolvedPlanId = planId ?? plan?.id ?? null;
    if (!resolvedPlanId) {
      throw new EdgeFunctionError("등록되지 않은 결제 상품입니다.", 400, "unknown_product");
    }

    const result = provider === "google_play"
      ? await verifyGooglePlayPurchase({ productId, purchaseToken, packageName: GOOGLE_PLAY_PACKAGE_NAME })
      : provider === "app_store"
        ? await verifyAppStorePurchase({ productId, purchaseToken, transactionId })
        : await verifyMockPurchase({ productId, purchaseToken });
    const purchaseTokenHash = await sha256Hex(purchaseToken);

    await client.from("purchase_verifications").upsert(
      {
        user_id: user.id,
        provider,
        product_id: productId,
        transaction_id: transactionId,
        purchase_token_hash: purchaseTokenHash,
        status: result.verified ? "verified" : "failed",
        plan_id: resolvedPlanId,
        expires_at: result.expiresAt,
        raw_response: result.rawResponse,
        error_code: result.errorCode ?? null,
      },
      { onConflict: "provider,transaction_id" },
    );

    if (!result.verified || result.status !== "active") {
      return errorResponse(
        "구매 영수증을 검증하지 못했습니다.",
        400,
        result.errorCode ?? "purchase_unverified",
      );
    }

    const subscriptionStatus = planStatusFor(result);
    await client.from("user_subscriptions").upsert(
      {
        user_id: user.id,
        plan_id: resolvedPlanId,
        status: subscriptionStatus,
        renews_at: result.expiresAt,
        provider,
        product_id: productId,
        transaction_id: transactionId,
        verified_at: new Date().toISOString(),
      },
      { onConflict: "user_id,plan_id" },
    );

    await client
      .from("profiles")
      .update({ is_premium: subscriptionStatus === "active", updated_at: new Date().toISOString() })
      .eq("id", user.id);

    await client.from("analytics_events").insert({
      user_id: user.id,
      event_name: "purchase_verified",
      properties: { provider, productId, planId: resolvedPlanId, transactionId },
    });

    return jsonResponse({
      verified: true,
      provider,
      productId,
      planId: resolvedPlanId,
      premiumActive: subscriptionStatus === "active",
      expiresAt: result.expiresAt,
    });
  } catch (error) {
    const edgeError = toEdgeFunctionError(error);
    return errorResponse(edgeError.message, edgeError.status, edgeError.code);
  }
});
