# Resource deletion behavior

Some objects in Figgy can't be deleted unless all their children have been
deleted. Some delete their children when they are deleted, and restore them when
they are restored. This distinction is generally made based on which object in
the relationship holds the membership reference.

Resources that can't be deleted until empty:
* Collection
* EphemeraProject
* EphemeraVocabulary

All other preservable resources delete their child resources, and restore them again if they are restored.
