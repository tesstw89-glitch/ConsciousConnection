import SwiftUI
import WebKit

struct ExerciseGIFView:
    UIViewRepresentable
{
    let url:
        URL

    func makeCoordinator()
        -> Coordinator
    {
        Coordinator()
    }


    func makeUIView(
        context: Context
    ) -> WKWebView {

        let configuration =
            WKWebViewConfiguration()

        let webView =
            WKWebView(
                frame: .zero,
                configuration:
                    configuration
            )

        webView.isOpaque =
            false

        webView.backgroundColor =
            .clear

        webView.scrollView
            .isScrollEnabled =
                false

        webView.scrollView
            .bounces =
                false

        webView
            .isUserInteractionEnabled =
                false

        return webView
    }


    func updateUIView(
        _ webView:
            WKWebView,
        context: Context
    ) {

        guard
            context
                .coordinator
                .loadedURL
                != url
        else {
            return
        }

        context
            .coordinator
            .loadedURL =
                url

        if url.isFileURL {
            loadLocalGIF(
                url,
                in:
                    webView
            )
        } else {
            loadRemoteGIF(
                url,
                in:
                    webView
            )
        }
    }


    private func loadRemoteGIF(
        _ url: URL,
        in webView:
            WKWebView
    ) {

        let escaped =
            escapeHTML(
                url.absoluteString
            )

        webView.loadHTMLString(
            html(
                imageSource:
                    escaped
            ),
            baseURL: nil
        )
    }


    private func loadLocalGIF(
        _ url: URL,
        in webView:
            WKWebView
    ) {

        let directory =
            url.deletingLastPathComponent()

        let filename =
            escapeHTML(
                url.lastPathComponent
            )

        webView.loadHTMLString(
            html(
                imageSource:
                    filename
            ),
            baseURL:
                directory
        )
    }


    private func html(
        imageSource: String
    ) -> String {

        """
        <!doctype html>
        <html>
        <head>
        <meta
            name="viewport"
            content="width=device-width,
                     initial-scale=1,
                     maximum-scale=1,
                     user-scalable=no">
        <style>
            html, body {
                margin: 0;
                padding: 0;
                width: 100%;
                height: 100%;
                background: transparent;
                overflow: hidden;
            }

            body {
                display: flex;
                align-items: center;
                justify-content: center;
            }

            img {
                width: 100%;
                height: 100%;
                object-fit: contain;
            }
        </style>
        </head>
        <body>
            <img
                src="\(imageSource)"
                alt="Exercise demonstration">
        </body>
        </html>
        """
    }


    private func escapeHTML(
        _ value: String
    ) -> String {

        value
            .replacingOccurrences(
                of: "&",
                with: "&amp;"
            )
            .replacingOccurrences(
                of: "\"",
                with: "&quot;"
            )
            .replacingOccurrences(
                of: "<",
                with: "&lt;"
            )
            .replacingOccurrences(
                of: ">",
                with: "&gt;"
            )
    }


    final class Coordinator {
        var loadedURL:
            URL?
    }
}
