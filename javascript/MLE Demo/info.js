import { graphql } from "graphql";
import { schema } from "schema";

const queryTemplate = `
   query BookQuery($searchTerm: String){
       library(research:$searchTerm){
           <<FIELDS>>
       }
   }
`;

export const getInfo = async (search, query) => {
  const fields = query.split(",").map(field => field.trim()).join("\n");
  const finalQuery = queryTemplate.replace("<<FIELDS>>", fields);
  const formattedSearch = search.replace(/\s/g, "+");
  const result = await graphql({ schema, source: finalQuery, variableValues:{searchTerm: formattedSearch }});
  return result.data ? result.data.library.items : [];
};
