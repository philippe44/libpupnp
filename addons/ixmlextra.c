/*
 * iXML extension
 * 
 *  (c) Philippe, philippe_44@outlook.com
 *
 * see LICENSE in repository
 * 
 */

#include <stdarg.h>
#include <string.h>
#include <stdio.h>

#include "ixmlextra.h"

#ifdef _WIN32
#define strdup _strdup
#define strcasecmp _stricmp
#else
#endif

/*----------------------------------------------------------------------------*/
IXML_Node* XMLAddNode(IXML_Document* doc, IXML_Node* parent, char* name, char* fmt, ...) {
	IXML_Node* elm = (IXML_Node*)ixmlDocument_createElement(doc, name);
	if (parent) ixmlNode_appendChild(parent, elm);
	else ixmlNode_appendChild((IXML_Node*)doc, elm);

	if (fmt) {
		char buf[1024];
		va_list args;
		
		va_start(args, fmt);

		vsnprintf(buf, sizeof(buf), fmt, args);
		IXML_Node* node = ixmlDocument_createTextNode(doc, buf);
		ixmlNode_appendChild(elm, node);

		va_end(args);
	}

	return elm;
}

/*----------------------------------------------------------------------------*/
IXML_Node* XMLUpdateNode(IXML_Document* doc, IXML_Node* parent, bool refresh, char* name, char* fmt, ...) {
	char buf[1024];
	va_list args;
	IXML_Node* node = (IXML_Node*)ixmlDocument_getElementById((IXML_Document*)parent, name);

	va_start(args, fmt);
	vsnprintf(buf, sizeof(buf), fmt, args);

	if (!node) {
		XMLAddNode(doc, parent, name, "%s", buf);
	} else if (refresh) {
		node = ixmlNode_getFirstChild(node);
		ixmlNode_setNodeValue(node, buf);
	}

	va_end(args);

	return node;
}

/*----------------------------------------------------------------------------*/
char* XMLDelNode(IXML_Node* from, char* name) {
	IXML_Node* self = (IXML_Node*)ixmlDocument_getElementById((IXML_Document*)from, name);
	if (!self) return NULL;

	IXML_Node* node = (IXML_Node*)ixmlNode_getParentNode(self);
	if (node) ixmlNode_removeChild(node, self, &self);

	node = ixmlNode_getFirstChild(self);
	char* value = (char*)ixmlNode_getNodeValue(node);
	if (value) value = strdup(value);

	ixmlNode_free(self);
	return value;
}

/*----------------------------------------------------------------------------*/
char* XMLGetFirstDocumentItem(IXML_Document* doc, const char* item, bool strict) {
	char* ret = NULL;
	IXML_NodeList* nodeList = ixmlDocument_getElementsByTagName(doc, (char*)item);

	for (int i = 0; nodeList && i < (int)ixmlNodeList_length(nodeList); i++) {
		IXML_Node* tmpNode = ixmlNodeList_item(nodeList, i);

		if (tmpNode) {
			IXML_Node* textNode = ixmlNode_getFirstChild(tmpNode);
			if (textNode) {
				ret = (char*)ixmlNode_getNodeValue(textNode);
				if (ret) {
					ret = strdup(ret);
					break;
				}
			}
		}

		if (strict) break;
	}

	if (nodeList) {
		ixmlNodeList_free(nodeList);
	} 

	return ret;
}


/*----------------------------------------------------------------------------*/
bool XMLMatchDocumentItem(IXML_Document* doc, const char* item, const char* s, bool match) {
	bool ret = false;

	IXML_NodeList* nodeList = ixmlDocument_getElementsByTagName(doc, (char*)item);

	for (int i = 0; nodeList && i < (int)ixmlNodeList_length(nodeList); i++) {
		IXML_Node* tmpNode = ixmlNodeList_item(nodeList, i);
		if (!tmpNode) continue;
		IXML_Node* textNode = ixmlNode_getFirstChild(tmpNode);
		if (!textNode) continue;
		const char *value = ixmlNode_getNodeValue(textNode);
		if ((match && !strcmp(value, s)) || (!match && value && strcasecmp(value, s))) {
			ret = true;
			break;
		}
	}

	if (nodeList) ixmlNodeList_free(nodeList);

	return ret;
}


/*----------------------------------------------------------------------------*/
char* XMLGetFirstElementItem(IXML_Element* element, const char* item) {
	char * ret = NULL;

	IXML_NodeList* nodeList = ixmlElement_getElementsByTagName(element, (char*)item);
	if (nodeList) {
		IXML_Node* tmpNode = ixmlNodeList_item(nodeList, 0);
		if (tmpNode) {
			IXML_Node* textNode = ixmlNode_getFirstChild(tmpNode);
			if (textNode) {
				ret = strdup(ixmlNode_getNodeValue(textNode));
			}
			ixmlNodeList_free(nodeList);
		}
	}

	return ret;
}


/*----------------------------------------------------------------------------*/
int XMLAddAttribute(IXML_Document* doc, IXML_Node* parent, char* name, char* fmt, ...) {
	char buf[1024];
	va_list args;

	va_start(args, fmt);
	vsnprintf(buf, sizeof(buf), fmt, args);
	int ret = ixmlElement_setAttribute((IXML_Element*) parent, name, buf);
	va_end(args);

	return ret;
}


/*----------------------------------------------------------------------------*/
const char* XMLGetLocalName(IXML_Document* doc, int Depth) {
	IXML_Node* node = (IXML_Node*)doc;

	while (Depth--) {
		node = ixmlNode_getFirstChild(node);
		if (!node) return NULL;
	}

	return ixmlNode_getLocalName(node);
}
