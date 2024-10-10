/*Copyright 2023,2024 Oracle and/or its affiliates.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import { makeExecutableSchema } from 'graphql-tools-schema';
import 'mle-js-fetch';
import oracledb from 'mle-js-oracledb';

const BASE_URL = "https://www.googleapis.com/books/v1/volumes?q=";

const typeDefs = `
  type ImageLinks {
    thumbnail: String
  }

  type Author {
    name: String
  }

  type VolumeInfo {
    title: String
    subtitle: String
    publisher: String
    description: String
    authors: [Author]
    publishedDate: String
    imageLinks: ImageLinks
    averageRating: Float
    pageCount: Int
    language: String
  }

  type Book {
    id: String
    kind: String
    etag: String
    volumeInfo: VolumeInfo
    stock: Int
  }

  type Volumes {
    kind: String
    totalItems: Int
    items: [Book]
  }

  type Query {
    library(research: String): Volumes
  }
`;

const resolvers = {
  Query: {
    library: async (_, { research }) => {
      return await getBooks(research);
    }
  },
  VolumeInfo: {
    authors: (volumeInfo) => volumeInfo.authors || [],
  },
  Book: {
    stock: async (book) => {
      const conn = oracledb.defaultConnection();
      const result = await conn.execute('SELECT stock FROM inventory WHERE id = :id', [book.id], { outFormat: oracledb.OUT_FORMAT_OBJECT });
      if (result.rows.length > 0) {
        return result.rows[0].STOCK;
      } else {
        return 0;
      }
    }
  },
};

const getBooks = async (SEARCH_URL) => {
  const conn = oracledb.defaultConnection();
  await conn.execute(`
    begin
      utl_http.set_wallet('file:/<absolute-path-to-your-wallet-directory>');
    end;
  `);
  const response = await fetch(`${BASE_URL}${SEARCH_URL}`, { credentials: "include" });
  const result = await response.json();
  return result;
};

export const schema = makeExecutableSchema({
  typeDefs,
  resolvers
});
