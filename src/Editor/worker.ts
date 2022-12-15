export const tmp = "";

/**
The data structure for documents. @nonabstract
*/
class Text {
  /**
    @internal
    */
}

class TextLeaf extends Text {}

interface ConnectionsTable {
  connectionId: {
    sub: string;
    documentId: string;
  };
}

interface DocumentsTable {
  documentId: {
    // sub
    creator: string;
    // Set<sub>
    users: Set<string>;
    // pointer to s3
    content: string;
  };
}
