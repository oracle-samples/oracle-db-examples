import {
    GraphQLSchema,
    GraphQLObjectType,
    GraphQLString,
    GraphQLInt,
    GraphQLFloat,
    GraphQLList
  } from 'graphql';
  import 'mle-js-fetch'; 
  import oracledb from 'mle-js-oracledb';
  
  const BASE_URL = "https://www.googleapis.com/books/v1/volumes?q=";
  
  const getBooks = async (SEARCH_URL) => {
  const conn = oracledb.defaultConnection();
  conn.execute(`
  begin
     utl_http.set_wallet('file:/home/smuench/apex/trunk/internal_utilities/dev/vagrant-devbox/scripts/CAcertBundle');
     utl_http.set_proxy('www-proxy-brmdc.us.oracle.com:80','oraclecorp.com');
  end;
  `);
  
  const response = await fetch(`${BASE_URL}${SEARCH_URL}`, { credentials: "include" });
  const result = await response.json();
  return result;
  }
  
  const imageLinks = new GraphQLObjectType({
    name: 'IMAGE_LINKS',
    fields: () => ({
        thumbnail: { 
            type: GraphQLString, 
        },
    })
  });
  
  const author = new GraphQLObjectType({
  name: 'AUTHOR',
  fields: () => ({
    name: { 
      type: GraphQLString,
      resolve: (author) => author || "Unknown",
    },
  })
  });
  
  const volumeInfo = new GraphQLObjectType({
  name: 'VOLUME_INFO',
  fields: () => ({
    title: {
        type: GraphQLString,
    },
    subtitle: {
        type: GraphQLString,
    },
    publisher: {
        type: GraphQLString,
    },
    description: {
        type: GraphQLString,
    },
    authors: {
        type: new GraphQLList(author),
        resolve: (volumeInfo) => volumeInfo.authors || [],
    },
    publishedDate: {
        type: GraphQLString,
    },
    imageLinks: {
        type: imageLinks,
    },
    averageRating: {
        type: GraphQLFloat,
    },
    pageCount: {
        type: GraphQLInt,
    },
    language: {
        type: GraphQLString,
    }
  })
  });
  
  const book = new GraphQLObjectType({
    name: 'BOOK',
    fields: () => ({
      id: {
        type: GraphQLString,
        description: 'The id of the book.',
      },
      kind: {
        type: GraphQLString,
        description: 'The kind of the book.',
      },
      etag: {
        type: GraphQLString,
        description: 'The etag of the book.',
      },
      volumeInfo: {
          type: volumeInfo,
      },
      stock: {
          type: GraphQLInt,
          resolve: (book) => {
              const result = session.execute('select stock from inventory where id = :id', [book.id]);
              if (result.rows.length > 0) {
                  return result.rows[0][0];
              } else {
                  return 0;
              }
          }
      },
    })
  });
  
  const volumes = new GraphQLObjectType({
  name: 'VOLUMES',
  fields: () => ({
    kind: { 
        type: GraphQLString, 
    },
    totalItems: { 
        type: GraphQLInt, 
    },
    items: { 
        type: new GraphQLList(book), 
    },
  }),
  });
  
  const queryType = new GraphQLObjectType({
      name: 'Query',
      fields: () => ({
        library: {
            args: {
                research: {
                    type: GraphQLString,
                },
            },
            type: volumes,
            resolve: async (_source, {research}) => await getBooks(research),
        },
      }),
  });
  
  export const schema = new GraphQLSchema({
    query: queryType,
    types: [volumes, book, volumeInfo, author, imageLinks]
  });