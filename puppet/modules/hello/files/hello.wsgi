# -*- mode: python-*-

def application(environ, start_response):
    status="200 OK"
    output="Hello World!\n\n" + sys.version "\n" + "\n".join(sys.path)
    response_headers=[("Content-Type", "text/html"), ("Content-Length", str(len(output)))]
    start_response(status, response_headers)
    return [output]
