#include "register_types.h"
#include "core/engine.h"
#include "reactgd/reactgd.h"
#include "reactgd/reactgdcomponent.h"

static ReactGD *reactgd_instance;

void register_reactgd_types() {
	ClassDB::register_class<ReactGD>();
	ClassDB::register_class<ReactGDComponent>();
	reactgd_instance = memnew(ReactGD);
	Engine::get_singleton()->add_singleton(Engine::Singleton("ReactGD", ReactGD::get_singleton()));
}

void unregister_reactgd_types() {
	if (reactgd_instance) {
		memdelete(reactgd_instance);
	}
}