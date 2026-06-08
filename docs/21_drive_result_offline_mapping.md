# Drive Result Offline Mapping

## 2026-06-06 Update
- Offline drive start creates a `local-drive-*` session and stores the local-to-server session mapping in `offline_drive_session_id_map` after queued session upload.
- Drive point sync remaps queued point batches to the uploaded server session ID, including retry runs after an earlier point upload failure.
- Sync attempts record item-level success/failure rows in `user_local_sync_logs` without storing coordinate payloads.
- Malformed `drive_points` payloads and unsupported legacy item types are logged as `discarded` and removed from the local queue, without increasing the uploaded count.
- Corrupted `offline_queue` storage is quarantined into `offline_queue_corrupt_backup`; valid rows from a partially bad queue are preserved.
- Drive result now resolves the route session ID through `OfflineQueueService.resolveDriveSessionId` before calling `finishDriveSession`.
- Drive result no longer calculates scores from sample fallback values. If the stored local summary is missing or invalid, it shows a recovery state and does not call `finishDriveSession`.
- Review request routing from the drive result screen uses the resolved session ID so support/fairness workflows target the official server session when one exists.

## Verification
- `flutter test test/widget/flow_screens_test.dart --plain-name "DriveResultScreen resolves local drive session before finish"` passed.
- `flutter test test/widget/flow_screens_test.dart --plain-name "DriveResultScreen missing local summary shows recovery without finish"` passed.
- `flutter test test/widget/flow_screens_test.dart --plain-name "DriveResultScreen fits 390px mobile width"` passed.
- `dart run tool/validate_product_invariants.dart` passed with 1819 checks.
