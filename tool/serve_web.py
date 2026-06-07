import argparse
import os
import urllib.parse
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class FlutterWebHandler(SimpleHTTPRequestHandler):
    root: Path

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cross-Origin-Resource-Policy', 'same-origin')
        super().end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        candidate = self.root / parsed.path.lstrip('/')
        if parsed.path != '/' and not candidate.exists():
            self.path = '/index.html'
        return super().do_GET()

    def log_message(self, format, *args):
        return


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--directory', default='build/web')
    parser.add_argument('--host', default='127.0.0.1')
    parser.add_argument('--port', type=int, default=5173)
    args = parser.parse_args()

    root = Path(args.directory).resolve()
    if not root.exists():
        raise SystemExit(f'web directory does not exist: {root}')

    FlutterWebHandler.root = root
    os.chdir(root)
    server = ThreadingHTTPServer((args.host, args.port), FlutterWebHandler)
    print(f'Serving {root} at http://{args.host}:{args.port}')
    server.serve_forever()


if __name__ == '__main__':
    main()
