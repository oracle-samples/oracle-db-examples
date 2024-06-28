/*
##  Copyright (c) 2024 Oracle and/or its affiliates.
##
## The Universal Permissive License (UPL), Version 1.0
##
## Subject to the condition set forth below, permission is hereby granted to any
## person obtaining a copy of this software, associated documentation and/or data
## (collectively the "Software"), free of charge and under any and all copyright
## rights in the Software, and any and all patent rights owned or freely
## licensable by each licensor hereunder covering either (i) the unmodified
## Software as contributed to or provided by such licensor, or (ii) the Larger
## Works (as defined below), to deal in both
##
## (a) the Software, and
## (b) any piece of software and/or hardware listed in the lrgrwrks.txt file if
## one is included with the Software (each a "Larger Work" to which the Software
## is contributed by such licensors),
##
## without restriction, including without limitation the rights to copy, create
## derivative works of, display, perform, and distribute the Software and make,
## use, sell, offer for sale, import, export, have made, and have sold the
## Software and the Larger Work(s), and to sublicense the foregoing rights on
## either these or other terms.
##
## This license is subject to the following condition:
## The above copyright notice and either this complete permission notice or at
## a minimum a reference to the UPL must be included in all copies or
## substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.
*/

/**
 * This javascript class provides a basic interface example to read the data from Autonomous Database pre-authenticated URL.
 */
class AdbsParUrlClient {
    constructor(parUrl) {
        this.items = [];
        this.totalRecords = 0;
        this.collectionIndexPosition = 0;
        this.nextGetParUrl = parUrl;
        this.itemsSize = 0;
    }

    /**
     * Return the next record from the cache for the Pre-auth request url.
     */
    getNextItem() {
        if (this.collectionIndexPosition < this.itemsSize) {
            return this.items[this.collectionIndexPosition++];
        } else if (this.nextGetParUrl == null) {
            this.items = [];
            this.collectionIndexPosition = 0;
            this.nextGetParUrl = null;
            this.itemsSize = 0;
            return null;
        } else {
            this.items = [];
            this.collectionIndexPosition = 0;
            this.itemsSize = 0;
            var jsonResponse = this.fetchParUrlData();
            var hasMore = jsonResponse.hasMore;

            console.log("items returned: " + jsonResponse.items.length);
            this.totalRecords = this.totalRecords + jsonResponse.items.length;
            this.itemsSize = jsonResponse.items.length;

            for (var count = 0; count < jsonResponse.items.length; count++) {
                this.items.push(jsonResponse.items[count]);
            }

            console.log("hasMore: " + hasMore);
            if (hasMore) {
                var links = jsonResponse.links;
                for (var count = 0; count < links.length; count++) {
                    if (links[count]['rel'] == 'next') {
                        this.nextGetParUrl = links[count]['href'];
                        console.log("Next url href: " + this.nextGetParUrl);
                    }
                }
            } else {
                this.nextGetParUrl = null;
            }

            return this.items[this.collectionIndexPosition++];
        }
    }

    /**
     * Fetch the Par Url data by invoking HTTP Get call.
     */
    fetchParUrlData() {
        console.log("Invoking Get call on Url: " + this.nextGetParUrl);
        var request = new XMLHttpRequest();
        request.open("GET", this.nextGetParUrl, false);
        request.setRequestHeader("Content-Type", "application/json");
        request.send();

        console.log("Get Call status: " + request.status);

        if (request.status === 200) {
            return JSON.parse(request.responseText);
        } else {
            throw new Error("Failed to fetch the par url data");
        }
    }
}