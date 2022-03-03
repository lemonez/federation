Feature: Build Query Plan

Scenario: should not confuse union types with overlapping field names
  Given query
    """
    query {
      body {
        ...on Image {
          attributes {
            url
          }
        }
        ...on Text {
          attributes {
            bold
            text
          }
        }
      }
    }
    """
  Then query plan
    """
    {
      "kind": "QueryPlan",
      "node": {
        "kind": "Fetch",
        "serviceName": "documents",
        "variableUsages": [],
        "operationKind": "query",
        "operation": "{body{__typename ...on Image{attributes{url}}...on Text{attributes{bold text}}}}"
      }
    }
    """

Scenario: should use a single fetch when requesting a root field from one service
  Given query
    """
    query {
      me {
        name {
          first
        }
      }
    }
    """
  Then query plan
    """
    {
      "kind": "QueryPlan",
      "node": {
        "kind": "Fetch",
        "serviceName": "accounts",
        "variableUsages": [],
        "operationKind": "query",
        "operation": "{me{name{first}}}"
      }
    }
    """

Scenario: should use two independent fetches when requesting root fields from two services
  Given query
    """
    query {
      me {
        name {
          first
        }
      }
      topProducts {
        name
      }
    }
    """
  Then query plan
    """
    {
      "kind": "QueryPlan",
      "node": {
        "kind": "Parallel",
        "nodes": [
          {
            "kind": "Fetch",
            "serviceName": "accounts",
            "variableUsages": [],
            "operationKind": "query",
            "operation": "{me{name{first}}}"
          },
          {
            "kind": "Sequence",
            "nodes": [
              {
                "kind": "Fetch",
                "serviceName": "product",
                "variableUsages": [],
                "operationKind": "query",
                "operation": "{topProducts{__typename ...on Book{__typename isbn}...on Furniture{name}}}"
              },
              {
                "kind": "Flatten",
                "path": ["topProducts", "@"],
                "node": {
                  "kind": "Fetch",
                  "serviceName": "books",
                  "requires": [
                    {
                      "kind": "InlineFragment",
                      "typeCondition": "Book",
                      "selections": [
                        { "kind": "Field", "name": "__typename" },
                        { "kind": "Field", "name": "isbn" }
                      ]
                    }
                  ],
                  "variableUsages": [],
                  "operationKind": "query",
                  "operation": "query($representations:[_Any!]!){_entities(representations:$representations){...on Book{title year}}}"
                }
              },
              {
                "kind": "Flatten",
                "path": ["topProducts", "@"],
                "node": {
                  "kind": "Fetch",
                  "serviceName": "product",
                  "requires": [
                    {
                      "kind": "InlineFragment",
                      "typeCondition": "Book",
                      "selections": [
                        { "kind": "Field", "name": "__typename" },
                        { "kind": "Field", "name": "title" },
                        { "kind": "Field", "name": "year" },
                        { "kind": "Field", "name": "isbn" }
                      ]
                    }
                  ],
                  "variableUsages": [],
                  "operationKind": "query",
                  "operation": "query($representations:[_Any!]!){_entities(representations:$representations){...on Book{name}}}"
                }
              }
            ]
          }
        ]
      }
    }
    """

Scenario: should use a single fetch when requesting multiple root fields from the same service
  Given query
    """
    query {
      topProducts {
        name
      }
      product(upc: "1") {
        name
      }
    }
    """
  Then query plan
    """
    {
      "kind": "QueryPlan",
      "node": {
        "kind": "Sequence",
        "nodes": [
          {
            "kind": "Fetch",
            "serviceName": "product",
            "variableUsages": [],
            "operationKind": "query",
            "operation": "{topProducts{__typename ...on Book{__typename isbn}...on Furniture{name}}product(upc:\"1\"){__typename ...on Book{__typename isbn}...on Furniture{name}}}"
          },
          {
            "kind": "Parallel",
            "nodes": [
              {
                "kind": "Sequence",
                "nodes": [
                  {
                    "kind": "Flatten",
                    "path": ["topProducts", "@"],
                    "node": {
                      "kind": "Fetch",
                      "serviceName": "books",
                      "requires": [
                        {
                          "kind": "InlineFragment",
                          "typeCondition": "Book",
                          "selections": [
                            { "kind": "Field", "name": "__typename" },
                            { "kind": "Field", "name": "isbn" }
                          ]
                        }
                      ],
                      "variableUsages": [],
                      "operationKind": "query",
                      "operation": "query($representations:[_Any!]!){_entities(representations:$representations){...on Book{title year}}}"
                    }
                  },
                  {
                    "kind": "Flatten",
                    "path": ["topProducts", "@"],
                    "node": {
                      "kind": "Fetch",
                      "serviceName": "product",
                      "requires": [
                        {
                          "kind": "InlineFragment",
                          "typeCondition": "Book",
                          "selections": [
                            { "kind": "Field", "name": "__typename" },
                            { "kind": "Field", "name": "title" },
                            { "kind": "Field", "name": "year" },
                            { "kind": "Field", "name": "isbn" }
                          ]
                        }
                      ],
                      "variableUsages": [],
                      "operationKind": "query",
                      "operation": "query($representations:[_Any!]!){_entities(representations:$representations){...on Book{name}}}"
                    }
                  }
                ]
              },
              {
                "kind": "Sequence",
                "nodes": [
                  {
                    "kind": "Flatten",
                    "path": ["product"],
                    "node": {
                      "kind": "Fetch",
                      "serviceName": "books",
                      "requires": [
                        {
                          "kind": "InlineFragment",
                          "typeCondition": "Book",
                          "selections": [
                            { "kind": "Field", "name": "__typename" },
                            { "kind": "Field", "name": "isbn" }
                          ]
                        }
                      ],
                      "variableUsages": [],
                      "operationKind": "query",
                      "operation": "query($representations:[_Any!]!){_entities(representations:$representations){...on Book{title year}}}"
                    }
                  },
                  {
                    "kind": "Flatten",
                    "path": ["product"],
                    "node": {
                      "kind": "Fetch",
                      "serviceName": "product",
                      "requires": [
                        {
                          "kind": "InlineFragment",
                          "typeCondition": "Book",
                          "selections": [
                            { "kind": "Field", "name": "__typename" },
                            { "kind": "Field", "name": "title" },
                            { "kind": "Field", "name": "year" },
                            { "kind": "Field", "name": "isbn" }
                          ]
                        }
                      ],
                      "variableUsages": [],
                      "operationKind": "query",
                      "operation": "query($representations:[_Any!]!){_entities(representations:$representations){...on Book{name}}}"
                    }
                  }
                ]
              }
            ]
          }
        ]
      }
    }
    """

Scenario: should use a single fetch when requesting relationship subfields from the same service
  Given query
    """
    query {
      topReviews {
        body
        author {
          reviews {
            body
          }
        }
      }
    }
    """
  Then query plan
    """
    {
      "kind": "QueryPlan",
      "node": {
        "kind": "Fetch",
        "serviceName": "reviews",
        "variableUsages": [],
        "operationKind": "query",
        "operation": "{topReviews{body author{reviews{body}}}}"
      }
    }
    """

Scenario: should use a single fetch when requesting relationship subfields and provided keys from the same service
  Given query
    """
    query {
      topReviews {
        body
        author {
          id
          reviews {
            body
          }
        }
      }
    }
    """
  Then query plan
    """
    {
      "kind": "QueryPlan",
      "node": {
        "kind": "Fetch",
        "serviceName": "reviews",
        "variableUsages": [],
        "operationKind": "query",
        "operation": "{topReviews{body author{id reviews{body}}}}"
      }
    }
    """

Scenario: when requesting an extension field from another service, it should add the field's representation requirements to the parent selection set and use a dependent fetch
  Given query
  """
  query {
    me {
      name {
        first
      }
      reviews {
        body
      }
    }
  }
  """
  Then query plan
    """
    {
      "kind": "QueryPlan",
      "node": {
        "kind": "Sequence",
        "nodes": [
          {
            "kind": "Fetch",
            "serviceName": "accounts",
            "variableUsages": [],
            "operationKind": "query",
            "operation": "{me{__typename id name{first}}}"
          },
          {
            "kind": "Flatten",
            "path": ["me"],
            "node": {
              "kind": "Fetch",
              "serviceName": "reviews",
              "requires": [
                {
                  "kind": "InlineFragment",
                  "typeCondition": "User",
                  "selections": [
                    { "kind": "Field", "name": "__typename" },
                    { "kind": "Field", "name": "id" }
                  ]
                }
              ],
              "variableUsages": [],
              "operationKind": "query",
              "operation": "query($representations:[_Any!]!){_entities(representations:$representations){...on User{reviews{body}}}}"
            }
          }
        ]
      }
    }
    """

Scenario: when requesting an extension field from another service, when the parent selection set is empty, should add the field's requirements to the parent selection set and use a dependent fetch
  Given query
    """
    query {
      me {
        reviews {
          body
        }
      }
    }
    """
  Then query plan
    """
    {
      "kind": "QueryPlan",
      "node": {
        "kind": "Sequence",
        "nodes": [
          {
            "kind": "Fetch",
            "serviceName": "accounts",
            "variableUsages": [],
            "operationKind": "query",
            "operation": "{me{__typename id}}"
          },
          {
            "kind": "Flatten",
            "path": ["me"],
            "node": {
              "kind": "Fetch",
              "serviceName": "reviews",
              "requires": [
                {
                  "kind": "InlineFragment",
                  "typeCondition": "User",
                  "selections": [
                    { "kind": "Field", "name": "__typename" },
                    { "kind": "Field", "name": "id" }
                  ]
                }
              ],
              "variableUsages": [],
              "operationKind": "query",
              "operation": "query($representations:[_Any!]!){_entities(representations:$representations){...on User{reviews{body}}}}"
            }
          }
        ]
      }
    }
    """

Scenario: when requesting an extension field from another service, should only add requirements once
  Given query
    """
    query {
      me {
        reviews {
          body
        }
        numberOfReviews
      }
    }
    """
  Then query plan
    """
    {
      "kind": "QueryPlan",
      "node": {
        "kind": "Sequence",
        "nodes": [
          {
            "kind": "Fetch",
            "serviceName": "accounts",
            "variableUsages": [],
            "operationKind": "query",
            "operation": "{me{__typename id}}"
          },
          {
            "kind": "Flatten",
            "path": ["me"],
            "node": {
              "kind": "Fetch",
              "serviceName": "reviews",
              "requires": [
                {
                  "kind": "InlineFragment",
                  "typeCondition": "User",
                  "selections": [
                    { "kind": "Field", "name": "__typename" },
                    { "kind": "Field", "name": "id" }
                  ]
                }
              ],
              "variableUsages": [],
              "operationKind": "query",
              "operation": "query($representations:[_Any!]!){_entities(representations:$representations){...on User{reviews{body}numberOfReviews}}}"
            }
          }
        ]
      }
    }
    """

Scenario: when requesting a composite field with subfields from another service, it should add key fields to the parent selection set and use a dependent fetch
  Given query
    """
    query {
      topReviews {
        body
        author {
          name {
            first
          }
        }
      }
    }
    """
  Then query plan
    """
    {
      "kind": "QueryPlan",
      "node": {
        "kind": "Sequence",
        "nodes": [
          {
            "kind": "Fetch",
            "serviceName": "reviews",
            "variableUsages": [],
            "operationKind": "query",
            "operation": "{topReviews{body author{__typename id}}}"
          },
          {
            "kind": "Flatten",
            "path": ["topReviews", "@", "author"],
            "node": {
              "kind": "Fetch",
              "serviceName": "accounts",
              "requires": [
                {
                  "kind": "InlineFragment",
                  "typeCondition": "User",
                  "selections": [
                    { "kind": "Field", "name": "__typename" },
                    { "kind": "Field", "name": "id" }
                  ]
                }
              ],
              "variableUsages": [],
              "operationKind": "query",
              "operation": "query($representations:[_Any!]!){_entities(representations:$representations){...on User{name{first}}}}"
            }
          }
        ]
      }
    }
    """

Scenario: when requesting a composite field with subfields from another service, when requesting a field defined in another service which requires a field in the base service, it should add the field provided by base service in first Fetch
  Given query
    """
    query {
      topCars {
        retailPrice
      }
    }
    """
  Then query plan
    """
    {
      "kind": "QueryPlan",
      "node": {
        "kind": "Sequence",
        "nodes": [
          {
            "kind": "Fetch",
            "serviceName": "product",
            "variableUsages": [],
            "operationKind": "query",
            "operation": "{topCars{__typename id price}}"
          },
          {
            "kind": "Flatten",
            "path": ["topCars", "@"],
            "node": {
              "kind": "Fetch",
              "serviceName": "reviews",
              "requires": [
                {
                  "kind": "InlineFragment",
                  "typeCondition": "Car",
                  "selections": [
                    { "kind": "Field", "name": "__typename" },
                    { "kind": "Field", "name": "id" },
                    { "kind": "Field", "name": "price" }
                  ]
                }
              ],
              "variableUsages": [],
              "operationKind": "query",
              "operation": "query($representations:[_Any!]!){_entities(representations:$representations){...on Car{retailPrice}}}"
            }
          }
        ]
      }
    }
    """

Scenario: when requesting a composite field with subfields from another service, when the parent selection set is empty, it should add key fields to the parent selection set and use a dependent fetch
  Given query
    """
    query {
      topReviews {
        author {
          name {
            first
          }
        }
      }
    }
    """
  Then query plan
    """
    {
      "kind": "QueryPlan",
      "node": {
        "kind": "Sequence",
        "nodes": [
          {
            "kind": "Fetch",
            "serviceName": "reviews",
            "variableUsages": [],
            "operationKind": "query",
            "operation": "{topReviews{author{__typename id}}}"
          },
          {
            "kind": "Flatten",
            "path": ["topReviews", "@", "author"],
            "node": {
              "kind": "Fetch",
              "serviceName": "accounts",
              "requires": [
                {
                  "kind": "InlineFragment",
                  "typeCondition": "User",
                  "selections": [
                    { "kind": "Field", "name": "__typename" },
                    { "kind": "Field", "name": "id" }
                  ]
                }
              ],
              "variableUsages": [],
              "operationKind": "query",
              "operation": "query($representations:[_Any!]!){_entities(representations:$representations){...on User{name{first}}}}"
            }
          }
        ]
      }
    }
    """

Scenario: when requesting a relationship field with extension subfields from a different service, it should first fetch the object using a key from the base service and then pass through the requirements
  Given query
    """
    query {
      topReviews {
        author {
          birthDate
        }
      }
    }
    """
  Then query plan
    """
    {
      "kind": "QueryPlan",
      "node": {
        "kind": "Sequence",
        "nodes": [
          {
            "kind": "Fetch",
            "serviceName": "reviews",
            "variableUsages": [],
            "operationKind": "query",
            "operation": "{topReviews{author{__typename id}}}"
          },
          {
            "kind": "Flatten",
            "path": ["topReviews", "@", "author"],
            "node": {
              "kind": "Fetch",
              "serviceName": "accounts",
              "requires": [
                {
                  "kind": "InlineFragment",
                  "typeCondition": "User",
                  "selections": [
                    { "kind": "Field", "name": "__typename" },
                    { "kind": "Field", "name": "id" }
                  ]
                }
              ],
              "variableUsages": [],
              "operationKind": "query",
              "operation": "query($representations:[_Any!]!){_entities(representations:$representations){...on User{birthDate}}}"
            }
          }
        ]
      }
    }
    """

Scenario: for abstract types, it should add __typename when fetching objects of an interface type from a service
  Given query
    """
    query {
      topProducts {
        price
      }
    }
    """
  Then query plan
    """
    {
      "kind": "QueryPlan",
      "node": {
        "kind": "Fetch",
        "serviceName": "product",
        "variableUsages": [],
        "operationKind": "query",
        "operation": "{topProducts{__typename price}}"
      }
    }
    """

Scenario: should break up when traversing an extension field on an interface type from a service
  Given query
    """
    query {
      topProducts {
        price
        reviews {
          body
        }
      }
    }
    """
  Then query plan
    """
    {
      "kind": "QueryPlan",
      "node": {
        "kind": "Sequence",
        "nodes": [
          {
            "kind": "Fetch",
            "serviceName": "product",
            "variableUsages": [],
            "operationKind": "query",
            "operation": "{topProducts{__typename price ...on Book{__typename isbn}...on Furniture{__typename upc}}}"
          },
          {
            "kind": "Flatten",
            "path": ["topProducts", "@"],
            "node": {
              "kind": "Fetch",
              "serviceName": "reviews",
              "requires": [
                {
                  "kind": "InlineFragment",
                  "typeCondition": "Book",
                  "selections": [
                    { "kind": "Field", "name": "__typename" },
                    { "kind": "Field", "name": "isbn" }
                  ]
                },
                {
                  "kind": "InlineFragment",
                  "typeCondition": "Furniture",
                  "selections": [
                    { "kind": "Field", "name": "__typename" },
                    { "kind": "Field", "name": "upc" }
                  ]
                }
              ],
              "variableUsages": [],
              "operationKind": "query",
              "operation": "query($representations:[_Any!]!){_entities(representations:$representations){...on Book{reviews{body}}...on Furniture{reviews{body}}}}"
            }
          }
        ]
      }
    }
    """

Scenario: interface fragments should expand into possible types only
  Given query
    """
    query {
      books {
        ... on Product {
          name
          ... on Furniture {
            upc
          }
        }
      }
    }
    """
  Then query plan
    """
    {
      "kind": "QueryPlan",
      "node": {
        "kind": "Sequence",
        "nodes": [
          {
            "kind": "Fetch",
            "serviceName": "books",
            "variableUsages": [],
            "operationKind": "query",
            "operation": "{books{__typename isbn title year}}"
          },
          {
            "kind": "Flatten",
            "path": ["books", "@"],
            "node": {
              "kind": "Fetch",
              "serviceName": "product",
              "requires": [
                {
                  "kind": "InlineFragment",
                  "typeCondition": "Book",
                  "selections": [
                    { "kind": "Field", "name": "__typename" },
                    { "kind": "Field", "name": "isbn" },
                    { "kind": "Field", "name": "title" },
                    { "kind": "Field", "name": "year" }
                  ]
                }
              ],
              "variableUsages": [],
              "operationKind": "query",
              "operation": "query($representations:[_Any!]!){_entities(representations:$representations){...on Book{name}}}"
            }
          }
        ]
      }
    }
    """

Scenario: interface inside interface should expand into possible types only
  Given query
    """
    query {
      product(upc: "") {
        details {
          country
        }
      }
    }
    """
  Then query plan
    """
    {
      "kind": "QueryPlan",
      "node": {
        "kind": "Fetch",
        "serviceName": "product",
        "variableUsages": [],
        "operationKind": "query",
        "operation": "{product(upc:\"\"){__typename details{__typename country}}}"
      }
    }
    """

Scenario: should properly expand nested unions with inline fragments
  Given query
    """
    query {
      body {
        ... on Image {
          ... on Body {
            ... on Image {
              attributes {
                url
              }
            }
            ... on Text {
              attributes {
                bold
                text
              }
            }
          }
        }
        ... on Text {
          attributes {
            bold
          }
        }
      }
    }
    """
  Then query plan
    """
    {
      "kind": "QueryPlan",
      "node": {
        "kind": "Fetch",
        "serviceName": "documents",
        "variableUsages": [],
        "operationKind": "query",
        "operation": "{body{__typename ...on Image{attributes{url}}...on Text{attributes{bold}}}}"
      }
    }
    """

Scenario: deduplicates fields / selections regardless of adjacency and type condition nesting for inline fragments
  Given query
    """
    query {
      body {
        ... on NamedObject {
          ... on Text {
            attributes {
              bold
            }
          }
        }
        ... on Body {
          ... on Text {
            attributes {
              bold
              text
            }
          }
        }
        ... on Text {
          attributes {
            bold
            text
          }
        }
      }
    }
    """
  Then query plan
    """
    {
      "kind": "QueryPlan",
      "node": {
        "kind": "Fetch",
        "serviceName": "documents",
        "variableUsages": [],
        "operationKind": "query",
        "operation": "{body{__typename ...on Text{attributes{bold text}}}}"
      }
    }
    """

Scenario: deduplicates fields / selections regardless of adjacency and type condition nesting for named fragment spreads
  Given query
    """
    fragment TextFragment on Text {
      attributes {
        bold
        text
      }
    }

    query {
      body {
        ... on NamedObject {
          ...TextFragment
        }
        ... on Body {
          ...TextFragment
        }
        ...TextFragment
      }
    }
    """
  Then query plan
    """
    {
      "kind": "QueryPlan",
      "node": {
        "kind": "Fetch",
        "serviceName": "documents",
        "variableUsages": [],
        "operationKind": "query",
        "operation": "{body{__typename ...on Text{attributes{bold text}}}}"
      }
    }
    """

Scenario: supports basic, single-service mutation
  Given query
  """
  mutation Login($username: String!, $password: String!) {
    login(username: $username, password: $password) {
      id
    }
  }
  """
  Then query plan
  """
  {
    "kind": "QueryPlan",
    "node": {
      "kind": "Fetch",
      "serviceName": "accounts",
      "variableUsages": [
        "username",
        "password"
      ],
      "operationKind": "mutation",
      "operation": "mutation Login_accounts_0($username:String!$password:String!){login(username:$username password:$password){id}}",
      "operationName": "Login_accounts_0"
    }
  }
  """

# ported from: https://github.com/apollographql/apollo-server/blob/main/packages/apollo-gateway/src/__tests__/integration/mutations.test.ts#L13
Scenario: supports mutations with a cross-service request
  Given query
  """
  mutation Login($username: String!, $password: String!) {
    login(username: $username, password: $password) {
      reviews {
        product {
          upc
        }
      }
    }
  }
  """
  Then query plan
  """
  {
    "kind": "QueryPlan",
    "node": {
      "kind": "Sequence",
      "nodes": [
        {
          "kind": "Fetch",
          "serviceName": "accounts",
          "variableUsages": [
            "username",
            "password"
          ],
          "operationKind": "mutation",
          "operation": "mutation Login_accounts_0($username:String!$password:String!){login(username:$username password:$password){__typename id}}",
          "operationName": "Login_accounts_0"
        },
        {
          "kind": "Flatten",
          "path": [
            "login"
          ],
          "node": {
            "kind": "Fetch",
            "serviceName": "reviews",
            "requires": [
              {
                "kind": "InlineFragment",
                "typeCondition": "User",
                "selections": [
                  {
                    "kind": "Field",
                    "name": "__typename"
                  },
                  {
                    "kind": "Field",
                    "name": "id"
                  }
                ]
              }
            ],
            "variableUsages": [],
            "operationKind": "query",
            "operation": "query Login_reviews_1($representations:[_Any!]!){_entities(representations:$representations){...on User{reviews{product{__typename ...on Book{__typename isbn}...on Furniture{upc}}}}}}",
            "operationName": "Login_reviews_1"
          }
        },
        {
          "kind": "Flatten",
          "path": [
            "login",
            "reviews",
            "@",
            "product"
          ],
          "node": {
            "kind": "Fetch",
            "serviceName": "product",
            "requires": [
              {
                "kind": "InlineFragment",
                "typeCondition": "Book",
                "selections": [
                  {
                    "kind": "Field",
                    "name": "__typename"
                  },
                  {
                    "kind": "Field",
                    "name": "isbn"
                  }
                ]
              }
            ],
            "variableUsages": [],
            "operationKind": "query",
            "operation": "query Login_product_2($representations:[_Any!]!){_entities(representations:$representations){...on Book{upc}}}",
            "operationName": "Login_product_2"
          }
        }
      ]
    }
  }
  """

# ported from: https://github.com/apollographql/apollo-server/blob/main/packages/apollo-gateway/src/__tests__/integration/mutations.test.ts#L48
Scenario: returning across service boundaries
  Given query
  """
  mutation Review($upc: String!, $body: String!) {
    reviewProduct(input: {upc: $upc, body: $body}) {
      ... on Furniture {
        name
      }
    }
  }
  """
  Then query plan
  """
  {
    "kind": "QueryPlan",
    "node": {
      "kind": "Sequence",
      "nodes": [
        {
          "kind": "Fetch",
          "serviceName": "reviews",
          "variableUsages": [
            "upc",
            "body"
          ],
          "operationKind": "mutation",
          "operation": "mutation Review_reviews_0($upc:String!$body:String!){reviewProduct(input:{upc:$upc body:$body}){__typename ...on Furniture{__typename upc}}}",
          "operationName": "Review_reviews_0"
        },
        {
          "kind": "Flatten",
          "path": [
            "reviewProduct"
          ],
          "node": {
            "kind": "Fetch",
            "serviceName": "product",
            "requires": [
              {
                "kind": "InlineFragment",
                "typeCondition": "Furniture",
                "selections": [
                  {
                    "kind": "Field",
                    "name": "__typename"
                  },
                  {
                    "kind": "Field",
                    "name": "upc"
                  }
                ]
              }
            ],
            "variableUsages": [],
            "operationKind": "query",
            "operation": "query Review_product_1($representations:[_Any!]!){_entities(representations:$representations){...on Furniture{name}}}",
            "operationName": "Review_product_1"
          }
        }
      ]
    }
  }
  """

# ported from: https://github.com/apollographql/apollo-server/blob/main/packages/apollo-gateway/src/__tests__/integration/mutations.test.ts#L75
Scenario: supports multiple root mutations
  Given query
  """
  mutation LoginAndReview(
    $username: String!
    $password: String!
    $upc: String!
    $body: String!
  ) {
    login(username: $username, password: $password) {
      reviews {
        product {
          upc
        }
      }
    }
    reviewProduct(input: {upc: $upc, body: $body}) {
      ... on Furniture {
        name
      }
    }
  }
  """
  Then query plan
  """
  {
    "kind": "QueryPlan",
    "node": {
      "kind": "Sequence",
      "nodes": [
        {
          "kind": "Fetch",
          "serviceName": "accounts",
          "variableUsages": [
            "username",
            "password"
          ],
          "operationKind": "mutation",
          "operation": "mutation LoginAndReview_accounts_0($username:String!$password:String!){login(username:$username password:$password){__typename id}}",
          "operationName": "LoginAndReview_accounts_0"
        },
        {
          "kind": "Flatten",
          "path": [
            "login"
          ],
          "node": {
            "kind": "Fetch",
            "serviceName": "reviews",
            "requires": [
              {
                "kind": "InlineFragment",
                "typeCondition": "User",
                "selections": [
                  {
                    "kind": "Field",
                    "name": "__typename"
                  },
                  {
                    "kind": "Field",
                    "name": "id"
                  }
                ]
              }
            ],
            "variableUsages": [],
            "operationKind": "query",
            "operation": "query LoginAndReview_reviews_1($representations:[_Any!]!){_entities(representations:$representations){...on User{reviews{product{__typename ...on Book{__typename isbn}...on Furniture{upc}}}}}}",
            "operationName": "LoginAndReview_reviews_1"
          }
        },
        {
          "kind": "Flatten",
          "path": [
            "login",
            "reviews",
            "@",
            "product"
          ],
          "node": {
            "kind": "Fetch",
            "serviceName": "product",
            "requires": [
              {
                "kind": "InlineFragment",
                "typeCondition": "Book",
                "selections": [
                  {
                    "kind": "Field",
                    "name": "__typename"
                  },
                  {
                    "kind": "Field",
                    "name": "isbn"
                  }
                ]
              }
            ],
            "variableUsages": [],
            "operationKind": "query",
            "operation": "query LoginAndReview_product_2($representations:[_Any!]!){_entities(representations:$representations){...on Book{upc}}}",
            "operationName": "LoginAndReview_product_2"
          }
        },
        {
          "kind": "Fetch",
          "serviceName": "reviews",
          "variableUsages": [
            "upc",
            "body"
          ],
          "operationKind": "mutation",
          "operation": "mutation LoginAndReview_reviews_3($upc:String!$body:String!){reviewProduct(input:{upc:$upc body:$body}){__typename ...on Furniture{__typename upc}}}",
          "operationName": "LoginAndReview_reviews_3"
        },
        {
          "kind": "Flatten",
          "path": [
            "reviewProduct"
          ],
          "node": {
            "kind": "Fetch",
            "serviceName": "product",
            "requires": [
              {
                "kind": "InlineFragment",
                "typeCondition": "Furniture",
                "selections": [
                  {
                    "kind": "Field",
                    "name": "__typename"
                  },
                  {
                    "kind": "Field",
                    "name": "upc"
                  }
                ]
              }
            ],
            "variableUsages": [],
            "operationKind": "query",
            "operation": "query LoginAndReview_product_4($representations:[_Any!]!){_entities(representations:$representations){...on Furniture{name}}}",
            "operationName": "LoginAndReview_product_4"
          }
        }
      ]
    }
  }
  """

# ported from: https://github.com/apollographql/apollo-server/blob/main/packages/apollo-gateway/src/__tests__/integration/mutations.test.ts#L136
Scenario: multiple root mutations with correct service order
  Given query
  """
  mutation LoginAndReview(
    $upc: String!
    $body: String!
    $updatedReview: UpdateReviewInput!
    $username: String!
    $password: String!
    $reviewId: ID!
  ) {
    reviewProduct(input: {upc: $upc, body: $body}) {
      ... on Furniture {
        upc
      }
    }
    updateReview(review: $updatedReview) {
      id
      body
    }
    login(username: $username, password: $password) {
      reviews {
        product {
          upc
        }
      }
    }
    deleteReview(id: $reviewId)
  }
  """
  Then query plan
  """
  {
    "kind": "QueryPlan",
    "node": {
      "kind": "Sequence",
      "nodes": [
        {
          "kind": "Fetch",
          "serviceName": "reviews",
          "variableUsages": [
            "upc",
            "body",
            "updatedReview"
          ],
          "operationKind": "mutation",
          "operation": "mutation LoginAndReview_reviews_0($upc:String!$body:String!$updatedReview:UpdateReviewInput!){reviewProduct(input:{upc:$upc body:$body}){__typename ...on Furniture{upc}}updateReview(review:$updatedReview){id body}}",
          "operationName": "LoginAndReview_reviews_0"
        },
        {
          "kind": "Fetch",
          "serviceName": "accounts",
          "variableUsages": [
            "username",
            "password"
          ],
          "operationKind": "mutation",
          "operation": "mutation LoginAndReview_accounts_1($username:String!$password:String!){login(username:$username password:$password){__typename id}}",
          "operationName": "LoginAndReview_accounts_1"
        },
        {
          "kind": "Flatten",
          "path": [
            "login"
          ],
          "node": {
            "kind": "Fetch",
            "serviceName": "reviews",
            "requires": [
              {
                "kind": "InlineFragment",
                "typeCondition": "User",
                "selections": [
                  {
                    "kind": "Field",
                    "name": "__typename"
                  },
                  {
                    "kind": "Field",
                    "name": "id"
                  }
                ]
              }
            ],
            "variableUsages": [],
            "operationKind": "query",
            "operation": "query LoginAndReview_reviews_2($representations:[_Any!]!){_entities(representations:$representations){...on User{reviews{product{__typename ...on Book{__typename isbn}...on Furniture{upc}}}}}}",
            "operationName": "LoginAndReview_reviews_2"
          }
        },
        {
          "kind": "Flatten",
          "path": [
            "login",
            "reviews",
            "@",
            "product"
          ],
          "node": {
            "kind": "Fetch",
            "serviceName": "product",
            "requires": [
              {
                "kind": "InlineFragment",
                "typeCondition": "Book",
                "selections": [
                  {
                    "kind": "Field",
                    "name": "__typename"
                  },
                  {
                    "kind": "Field",
                    "name": "isbn"
                  }
                ]
              }
            ],
            "variableUsages": [],
            "operationKind": "query",
            "operation": "query LoginAndReview_product_3($representations:[_Any!]!){_entities(representations:$representations){...on Book{upc}}}",
            "operationName": "LoginAndReview_product_3"
          }
        },
        {
          "kind": "Fetch",
          "serviceName": "reviews",
          "variableUsages": [
            "reviewId"
          ],
          "operationKind": "mutation",
          "operation": "mutation LoginAndReview_reviews_4($reviewId:ID!){deleteReview(id:$reviewId)}",
          "operationName": "LoginAndReview_reviews_4"
        }
      ]
    }
  }
  """
