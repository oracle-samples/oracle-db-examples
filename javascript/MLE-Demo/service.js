import { graphql } from "graphql";
import { schema } from "schema";

const queryTemplate = `
   query BookQuery($searchTerm: String) {
       library(research: $searchTerm) {
            items {
                volumeInfo{
                    title,
                    subtitle,
                    description,
                    imageLinks{
                        thumbnail,
                    },
                    authors{
                        name,
                    },
                }
            }
       }
   }
`;

async function getInfo(search) {
  try {
    const result = await graphql({
      schema,
      source: queryTemplate,
      variableValues: {
        searchTerm: search
      }
    });

    if (!result || !result.data) {
      const errorMessage = result && result.errors ? result.errors[0].message : 'No data found';
      throw new Error(errorMessage);
    }

    const volumeInfos = result.data.library.items.map(item => item.volumeInfo);
    return volumeInfos;
  } catch (error) {
    throw new Error(`Error retrieving information: ${error.message}`);
  }
}
