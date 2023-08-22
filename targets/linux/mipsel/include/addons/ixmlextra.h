/*
 * iXML extension
 *
 *  (c) Philippe, philippe_44@outlook.com
 *
 * see LICENSE in repository
 *
 */

#pragma once

#include <stdbool.h>
#include "ixml.h"

const char*	XMLGetLocalName(IXML_Document *doc, int Depth);
IXML_Node*	XMLAddNode(IXML_Document *doc, IXML_Node *parent, const char *name, const char *fmt, ...);
IXML_Node*	XMLUpdateNode(IXML_Document *doc, IXML_Node *parent, bool refresh, char const *name, const char *fmt, ...);
char*		XMLDelNode(IXML_Node* from, const char* name);
int 	   	XMLAddAttribute(IXML_Document *doc, IXML_Node *parent, const char *name, const char *fmt, ...);
char*		XMLGetFirstDocumentItem(IXML_Document *doc, const char *item, bool strict);
char*		XMLGetFirstElementItem(IXML_Element *element, const char *item);
bool 		XMLMatchDocumentItem(IXML_Document *doc, const char *item, const char *s, bool match);
