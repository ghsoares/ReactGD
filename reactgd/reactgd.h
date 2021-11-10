#ifndef REACTGD_H
#define REACTGD_H

#include "core/reference.h"
#include "core/variant.h"
#include <vector>

class ReactGD : public Object {
	GDCLASS(ReactGD, Object)

	static ReactGD *singleton;

	const char* META_CACHED_TREE = "_REACTGD_CACHED_TREE";

protected:
	static void _bind_methods();

public:
	static ReactGD *get_singleton() {return ReactGD::singleton;}

	Dictionary create_node(String id, Ref<Reference> type, Dictionary props, Array children);
	bool update_node_props(Node *node, Dictionary props);
	Node *instantiate(Dictionary node);
	Node *render(Node *root, Array tree); 

	ReactGD();
	~ReactGD();
};

#endif