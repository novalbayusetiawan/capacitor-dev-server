package dev.novals.devserver;

import fi.iki.elonen.NanoHTTPD;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import android.webkit.MimeTypeMap;

public class LocalServer extends NanoHTTPD {
    private final File rootDir;

    public LocalServer(int port, File rootDir) {
        super(port);
        this.rootDir = rootDir;
    }

    @Override
    public Response serve(IHTTPSession session) {
        String uri = session.getUri();
        if (uri.endsWith("/")) {
            uri += "index.html";
        }

        File file = new File(rootDir, uri);
        
        // Security check: ensure file is within rootDir to prevent directory traversal
        try {
            if (!file.getCanonicalPath().startsWith(rootDir.getCanonicalPath())) {
                return newFixedLengthResponse(Response.Status.FORBIDDEN, NanoHTTPD.MIME_PLAINTEXT, "Forbidden");
            }
        } catch (IOException e) {
             return newFixedLengthResponse(Response.Status.INTERNAL_ERROR, NanoHTTPD.MIME_PLAINTEXT, "Internal Error");
        }

        if (file.exists() && file.isFile()) {
            String mimeType = getMimeType(file.getName());
            try {
                FileInputStream fis = new FileInputStream(file);
                return newChunkedResponse(Response.Status.OK, mimeType, fis);
            } catch (IOException e) {
                return newFixedLengthResponse(Response.Status.INTERNAL_ERROR, NanoHTTPD.MIME_PLAINTEXT, "Internal Error");
            }
        }

        return newFixedLengthResponse(Response.Status.NOT_FOUND, NanoHTTPD.MIME_PLAINTEXT, "Not Found");
    }

    private String getMimeType(String fileName) {
        String extension = MimeTypeMap.getFileExtensionFromUrl(fileName);
        if (extension != null) {
            String type = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension.toLowerCase());
            if (type != null) {
                return type;
            }
        }
        return "application/octet-stream";
    }
}
