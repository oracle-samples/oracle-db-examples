/*Copyright 2023 Oracle and/or its affiliates.

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
