import { addSubgraphToASTNode, ErrorCodeDefinition, joinStrings, MultiMap, NamedSchemaElement, printSubgraphNames, SubgraphASTNode } from '@apollo/federation-internals';
import { ASTNode, GraphQLError } from 'graphql';
import { CompositionHint, HintCodeDefinition } from '../hints';
import { Sources } from './merge';

export class MismatchReporter {
  pushError: (error: GraphQLError) => void;
  pushHint: (hint: CompositionHint) => void;

  constructor(readonly names: readonly string[], pushError: (error: GraphQLError) => void, pushHint: (hint: CompositionHint) => void) {
    this.pushError = pushError;
    this.pushHint = pushHint;
  }

  reportMismatchError<TMismatched extends { sourceAST?: ASTNode }>(
    code: ErrorCodeDefinition,
    message: string,
    mismatchedElement:TMismatched,
    subgraphElements: Sources<TMismatched>,
    mismatchAccessor: (elt: TMismatched, isSupergraph: boolean) => string | undefined
  ) {
    this.reportMismatch(
      mismatchedElement,
      subgraphElements,
      mismatchAccessor,
      (elt, names) => `${elt} in ${names}`,
      (elt, names) => `${elt} in ${names}`,
      (distribution, nodes) => {
        this.pushError(code.err(
          message + joinStrings(distribution, ' and ', ' but '),
          { nodes }
        ));
      },
      elt => !elt
    );
  }

  reportMismatchErrorWithoutSupergraph<TMismatched extends { sourceAST?: ASTNode }>(
    code: ErrorCodeDefinition,
    message: string,
    subgraphElements: Sources<TMismatched>,
    mismatchAccessor: (elt: TMismatched, isSupergraph: boolean) => string | undefined
  ) {
    this.reportMismatch(
      undefined,
      subgraphElements,
      mismatchAccessor,
      () => '',
      (elt, names) => `${elt} in ${names}`,
      (distribution, nodes) => {
        this.pushError(code.err(
          message + joinStrings(distribution, ' and ', ' but '),
          { nodes }
        ));
      },
      elt => !elt
    );
  }

  reportMismatchErrorWithSpecifics<TMismatched extends { sourceAST?: ASTNode }>({
    code,
    message,
    mismatchedElement,
    subgraphElements,
    mismatchAccessor,
    supergraphElementPrinter,
    otherElementsPrinter,
    ignorePredicate,
    includeMissingSources = false,
    extraNodes,
  }: {
    code: ErrorCodeDefinition,
    message: string,
    mismatchedElement: TMismatched,
    subgraphElements: Sources<TMismatched>,
    mismatchAccessor: (elt: TMismatched | undefined, isSupergraph: boolean) => string | undefined,
    supergraphElementPrinter: (elt: string, subgraphs: string | undefined) => string,
    otherElementsPrinter: (elt: string, subgraphs: string) => string,
    ignorePredicate?: (elt: TMismatched | undefined) => boolean,
    includeMissingSources?: boolean,
    extraNodes?: SubgraphASTNode[],
  }) {
    this.reportMismatch(
      mismatchedElement,
      subgraphElements,
      mismatchAccessor,
      supergraphElementPrinter,
      otherElementsPrinter,
      (distribution, nodes) => {
        this.pushError(code.err(
          message + distribution[0] + joinStrings(distribution.slice(1), ' and '),
          { nodes: nodes.concat(extraNodes ?? []) }
        ));
      },
      ignorePredicate,
      includeMissingSources
    );
  }

  reportMismatchHint<TMismatched extends { sourceAST?: ASTNode }>({
    code,
    message,
    supergraphElement,
    subgraphElements,
    targetedElement,
    elementToString,
    supergraphElementPrinter,
    otherElementsPrinter,
    ignorePredicate,
    includeMissingSources = false,
    noEndOfMessageDot = false,
  }: {
    code: HintCodeDefinition,
    message: string,
    supergraphElement: TMismatched,
    subgraphElements: Sources<TMismatched>,
    targetedElement?: NamedSchemaElement<any, any, any>
    elementToString: (elt: TMismatched, isSupergraph: boolean) => string | undefined,
    supergraphElementPrinter: (elt: string, subgraphs: string | undefined) => string,
    otherElementsPrinter: (elt: string, subgraphs: string) => string,
    ignorePredicate?: (elt: TMismatched | undefined) => boolean,
    includeMissingSources?: boolean,
    noEndOfMessageDot?: boolean
  }) {
    this.reportMismatch(
      supergraphElement,
      subgraphElements,
      elementToString,
      supergraphElementPrinter,
      otherElementsPrinter,
      (distribution, astNodes) => {
        this.pushHint(new CompositionHint(
          code,
          message + distribution[0] + joinStrings(distribution.slice(1), ' and ') + (noEndOfMessageDot ? '' : '.'),
          targetedElement ?? ((supergraphElement instanceof NamedSchemaElement) ? supergraphElement as NamedSchemaElement<any, any, any> : undefined),
          astNodes
        ));
      },
      ignorePredicate,
      includeMissingSources
    );
  }

  // Not meant to be used directly: use `reportMismatchError` or `reportMismatchHint` instead.
  private reportMismatch<TMismatched extends { sourceAST?: ASTNode }>(
    supergraphElement:TMismatched | undefined,
    subgraphElements: Sources<TMismatched>,
    mismatchAccessor: (element: TMismatched, isSupergraph: boolean) => string | undefined,
    supergraphElementPrinter: (elt: string, subgraphs: string | undefined) => string,
    otherElementsPrinter: (elt: string, subgraphs: string) => string,
    reporter: (distribution: string[], astNode: SubgraphASTNode[]) => void,
    ignorePredicate?: (elt: TMismatched | undefined) => boolean,
    includeMissingSources: boolean = false
  ) {
    const distributionMap = new MultiMap<string, string>();
    const astNodes: SubgraphASTNode[] = [];
    const processSubgraphElt = (name: string, subgraphElt: TMismatched) => {
      if (ignorePredicate && ignorePredicate(subgraphElt)) {
        return;
      }
      const elt = mismatchAccessor(subgraphElt, false);
      distributionMap.add(elt ?? '', name);
      if (subgraphElt.sourceAST) {
        astNodes.push(addSubgraphToASTNode(subgraphElt.sourceAST, name));
      }
    }
    if (includeMissingSources) {
      for (const [i, name] of this.names.entries()) {
        const subgraphElt = subgraphElements.get(i);
        if (!subgraphElt) {
          distributionMap.add('', name);
          continue;
        }
        processSubgraphElt(name, subgraphElt);
      }
    } else {
      for (const [i, subgraphElt] of subgraphElements.entries()) {
        if (!subgraphElt) {
          continue;
        }
        processSubgraphElt(this.names[i], subgraphElt);
      }
    }
    const supergraphMismatch = (supergraphElement && mismatchAccessor(supergraphElement, true)) ?? '';
    const distribution = [];
    // We always add the "supergraph" first (proper formatting of hints rely on this in particular).
    const subgraphsLikeSupergraph = distributionMap.get(supergraphMismatch);
    distribution.push(supergraphElementPrinter(supergraphMismatch, subgraphsLikeSupergraph ? printSubgraphNames(subgraphsLikeSupergraph) : undefined));
    for (const [v, names] of distributionMap.entries()) {
      if (v === supergraphMismatch) {
        continue;
      }
      distribution.push(otherElementsPrinter(v, printSubgraphNames(names)));
    }
    reporter(distribution, astNodes);
  }
}
