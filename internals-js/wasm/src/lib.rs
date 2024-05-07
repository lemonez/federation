use apollo_compiler::{diagnostic::Diagnostic, validation::DiagnosticData, Schema};
use apollo_federation::sources::connect::{validate, ValidationError};
use wasm_bindgen::prelude::wasm_bindgen;

#[wasm_bindgen]
pub fn validate_connect_directives(schema: String) -> Vec<GraphQLError> {
    let mut errors = Vec::new();
    // TODO: Get a real file name to add to diagnostics?
    // TODO: Make the federation extras a separate document so that the errors point to source.
    let schema = match Schema::parse(schema, "schema.graphql") {
        Ok(schema) => schema,
        Err(e) => {
            errors.extend(e.errors.iter().map(GraphQLError::from));
            e.partial
        }
    };
    errors.extend(validate(schema).into_iter().map(|e| e.into()));
    errors
}

/// Rust representation of `GraphQLError` from TypeScript
///
/// TODO: Import the JavaScript version directly to avoid extra copying?
#[wasm_bindgen]
pub struct GraphQLError {
    pub code: ErrorCode,
    message: String,
    location: Option<ErrorLocation>,
}

#[wasm_bindgen]
#[derive(Clone, Copy, Debug)]
pub enum ErrorCode {
    InvalidGraphQL = "INVALID_GRAPHQL",
    SourceUrlInvalid = "SOURCE_URL_INVALID",
}

#[wasm_bindgen]
impl GraphQLError {
    #[wasm_bindgen(getter)]
    pub fn message(&self) -> String {
        self.message.clone()
    }

    #[wasm_bindgen(getter)]
    pub fn location(&self) -> Option<ErrorLocation> {
        self.location.clone()
    }
}

/// In practice, this type of error should never be returned since GraphQL validation is happening
/// in JavaScript
impl From<Diagnostic<'_, DiagnosticData>> for GraphQLError {
    fn from(diagnostic: Diagnostic<DiagnosticData>) -> Self {
        GraphQLError {
            code: ErrorCode::InvalidGraphQL,
            message: diagnostic.to_string(),
            location: None,
        }
    }
}

impl From<ValidationError> for GraphQLError {
    fn from(error: ValidationError) -> Self {
        let message = error.to_string();
        match error {
            ValidationError::InvalidSourceUrl { source_name, .. }
            | ValidationError::InvalidSourceScheme { source_name, .. } => GraphQLError {
                code: ErrorCode::SourceUrlInvalid,
                message,
                location: Some(ErrorLocation {
                    source_directive: Some(SourceDirective { name: source_name }),
                }),
            },
        }
    }
}

#[wasm_bindgen]
#[derive(Clone, Debug)]
pub struct ErrorLocation {
    source_directive: Option<SourceDirective>,
    // TODO: connect: Option<Connect>,
}

#[wasm_bindgen]
impl ErrorLocation {
    #[wasm_bindgen(getter)]
    pub fn source(&self) -> Option<SourceDirective> {
        self.source_directive.clone()
    }
}

#[wasm_bindgen]
#[derive(Clone, Debug)]
pub struct SourceDirective {
    name: String,
}

#[wasm_bindgen]
impl SourceDirective {
    #[wasm_bindgen(getter)]
    pub fn name(&self) -> String {
        self.name.clone()
    }
}
