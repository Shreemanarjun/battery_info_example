package com.example.battery_info_example;

import androidx.annotation.Keep;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;

/**
 * Simple HTTP client for JNI access.
 *
 * This class provides basic HTTP GET and POST functionality using Java's HttpURLConnection.
 * It will be accessed from Dart via JNI using jnigen-generated bindings.
 *
 * NOTE: This is a simplified example for demonstration purposes.
 * In production code, consider using more robust HTTP libraries.
 */
@Keep
public class NetworkClient {

    public NetworkClient() {
        // Default constructor
    }

    /**
     * Perform a synchronous GET request.
     * @param urlString The URL to fetch
     * @return Response body as String, or error message prefixed with "ERROR:"
     */
    public String get(String urlString) {
        try {
            URL url = new URL(urlString);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("GET");
            connection.setConnectTimeout(5000);
            connection.setReadTimeout(5000);

            int responseCode = connection.getResponseCode();
            if (responseCode == HttpURLConnection.HTTP_OK) {
                BufferedReader reader = new BufferedReader(
                    new InputStreamReader(connection.getInputStream()));
                StringBuilder response = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) {
                    response.append(line);
                }
                reader.close();
                return response.toString();
            } else {
                return "ERROR: HTTP " + responseCode;
            }
        } catch (IOException e) {
            return "ERROR: " + e.getMessage();
        }
    }

    /**
     * Perform a synchronous POST request with JSON body.
     * @param urlString The URL to post to
     * @param jsonBody The JSON body as a String
     * @return Response body as String, or error message prefixed with "ERROR:"
     */
    public String post(String urlString, String jsonBody) {
        try {
            URL url = new URL(urlString);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("POST");
            connection.setRequestProperty("Content-Type", "application/json");
            connection.setRequestProperty("Accept", "application/json");
            connection.setDoOutput(true);
            connection.setConnectTimeout(5000);
            connection.setReadTimeout(5000);

            // Write JSON body
            try (OutputStream os = connection.getOutputStream()) {
                byte[] input = jsonBody.getBytes("utf-8");
                os.write(input, 0, input.length);
            }

            int responseCode = connection.getResponseCode();
            if (responseCode == HttpURLConnection.HTTP_OK ||
                responseCode == HttpURLConnection.HTTP_CREATED) {
                BufferedReader reader = new BufferedReader(
                    new InputStreamReader(connection.getInputStream()));
                StringBuilder response = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) {
                    response.append(line);
                }
                reader.close();
                return response.toString();
            } else {
                return "ERROR: HTTP " + responseCode;
            }
        } catch (IOException e) {
            return "ERROR: " + e.getMessage();
        }
    }
}
