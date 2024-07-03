/**
 * Copyright (c) 2024 Oracle and/or its affiliates.
 *
 * The Universal Permissive License (UPL), Version 1.0
 *
 * Subject to the condition set forth below, permission is hereby granted to any
 * person obtaining a copy of this software, associated documentation and/or data
 * (collectively the "Software"), free of charge and under any and all copyright
 * rights in the Software, and any and all patent rights owned or freely
 * licensable by each licensor hereunder covering either (i) the unmodified
 * Software as contributed to or provided by such licensor, or (ii) the Larger
 * Works (as defined below), to deal in both
 *
 * (a) the Software, and
 * (b) any piece of software and/or hardware listed in the lrgrwrks.txt file if
 * one is included with the Software (each a "Larger Work" to which the Software
 * is contributed by such licensors),
 *
 * without restriction, including without limitation the rights to copy, create
 * derivative works of, display, perform, and distribute the Software and make,
 * use, sell, offer for sale, import, export, have made, and have sold the
 * Software and the Larger Work(s), and to sublicense the foregoing rights on
 * either these or other terms.
 *
 * This license is subject to the following condition:
 * The above copyright notice and either this complete permission notice or at
 * a minimum a reference to the UPL must be included in all copies or
 * substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.apache.commons.lang3.BooleanUtils;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.util.List;

/**
 * This class provides a basic example of how to read the data from Autonomous Database pre-authenticated URL.
 *
 * <p>The example has some constraints. This is a single threaded example & cannot be used to fetch
 * the data from same AdbsParUrlClient instance in multiple threads.
 *
 * <p>This example will do the following things:
 *
 * <ul>
 *   <li>Accepts Autonomous Database pre-authenticated URL as input.
 *   <li>Returns an iterator used to iterate records one by one.
 * </ul>
 */
public class AdbsParUrlClient {
    /**
     * Pre Authenticated Request URL.
     */
    private final String adbsParUrl;

    /**
     * Constructor
     *
     * @param adbsParUrl Pre Authenticated Request URL.
     */
    public AdbsParUrlClient(String adbsParUrl) {
        this.adbsParUrl = adbsParUrl;
    }

    /**
     * Creates ResultSet object for iterating the results.
     *
     * @return ResultSet object for iterating the results.
     * @throws IOException if fetching data from par url fails.
     */
    public ResultSet execute() throws IOException {
        final ResultSet resultSet = new ResultSet(this.adbsParUrl);
        return resultSet;
    }

    /**
     * Par Url Response pojo class
     */
    @Getter
    @Setter
    @NoArgsConstructor
    public static class ParUrlResponse {
        private List<JsonNode> items;
        private Boolean hasMore;
        private long limit;
        private long offset;
        private long count;
        private List<Link> links;

        @Getter
        @Setter
        public static class Link {
            private String rel;
            private String href;
        }
    }

    /**
     * Helper class to iterate data fetched from the par url.
     */
    public static class ResultSet {
        private static final ObjectMapper mapper = new ObjectMapper();
        private int currentOffset;
        private ParUrlResponse parUrlResponse;

        /**
         * Constructor
         *
         * @param adbsParUrl Pre Authenticated Request URL.
         * @throws IOException if fetching data from par url fails.
         */
        public ResultSet(String adbsParUrl) throws IOException {
            this.parUrlResponse = fetchData(adbsParUrl);
            this.currentOffset = 0;
        }

        /**
         * Method to fetch data from the par url.
         *
         * @param adbsParUrl Pre Authenticated Request URL.
         * @return result pojo for the fetch par url data operation.
         * @throws IOException
         */
        private ParUrlResponse fetchData(String adbsParUrl) throws IOException {
            final CloseableHttpClient httpClient = HttpClients.createDefault();
            final HttpGet request = new HttpGet(adbsParUrl);
            final HttpResponse response = httpClient.execute(request);
            final int statusCode = response.getStatusLine().getStatusCode();

            if (statusCode == HttpURLConnection.HTTP_OK) { // success
                String responseStr = EntityUtils.toString(response.getEntity());
                return mapper.readValue(responseStr, ParUrlResponse.class);
            } else {
                //System.out.println(response.getStatusLine().toString());
                throw new RuntimeException("Error while fetching data for the par Url.");
            }

        }

        /**
         * Helper method to check if more items are still available.
         *
         * @return true if available else false
         */
        public boolean hasNext() {
            return currentOffset < parUrlResponse.getCount() || (currentOffset == parUrlResponse.getCount() &&
                BooleanUtils.isTrue(parUrlResponse.hasMore));
        }

        /**
         * Helper method to return the next item from the cached list.
         *
         * @return next item from the cached data list.
         * @throws IOException if fetching data from par url fails.
         */
        public JsonNode next() throws IOException {
            if (currentOffset < parUrlResponse.getCount()) {
                return parUrlResponse.getItems().get(currentOffset++);
            }

            this.currentOffset = 0;
            this.parUrlResponse = fetchData(getNextLink());
            return parUrlResponse.getItems().get(currentOffset++);
        }

        /**
         * Method to get the fetch link for the next page items.
         *
         * @return next page link.
         */
        private String getNextLink() {
            return parUrlResponse.links.stream()
                .filter(l -> "next".equalsIgnoreCase(l.rel))
                .map(l -> l.href)
                .findFirst().get();
        }
    }

    /**
     * Fetch Data from par url sample main method.
     *
     * @param args input arguments
     * @throws IOException if fetching data from par url fails.
     */
    public static void main(String[] args) throws IOException {

        /**
         * Setting sample Adbs par url
         */
        final String sampleAdbsParUrl = "https://dataaccess.adb.us-phoenix-1.oraclecloudapps.com/adb/p/NYGM5PicEMTe1hF.../data";

        /**
         * Initialize the class instance fetching par url data
         */
        AdbsParUrlClient parUrlClient = new AdbsParUrlClient(sampleAdbsParUrl);
        ResultSet rs = parUrlClient.execute();

        /**
         * Iterate the list until all records are returned.
         */
        while (rs.hasNext()) {
            JsonNode node = rs.next();
            System.out.println(node);
        }
    }
}

