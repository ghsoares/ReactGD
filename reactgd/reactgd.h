#ifndef REACTGD_H
#define REACTGD_H

#include "core/reference.h"
#include "core/variant.h"

class ReactGD : public Object {
	GDCLASS(ReactGD, Object)

	static ReactGD *singleton;

protected:
	static void _bind_methods();

private:
	void _render(Node *root, Dictionary tree, int &child_idx); 

public:
	static ReactGD *get_singleton() {return ReactGD::singleton;}

	Dictionary create_node(String id, Ref<Reference> type, Dictionary props, Array children);
	bool update_node_props(Node *node, Dictionary props);
	Node *instantiate(Dictionary node);
	void render(Node *root, Dictionary tree);

	ReactGD();
	~ReactGD();
};

#endif