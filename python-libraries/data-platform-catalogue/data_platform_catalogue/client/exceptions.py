class CatalogueError(Exception):
    """
    Base class for catalogue-related errors.
    """


class ReferencedEntityMissing(CatalogueError):
    """
    A referenced entity (such as a user or tag) does not yet exist when
    attempting to create a new metadata resource in the catalogue.
    """


class InvalidDomain(CatalogueError):
    """
    Domain does not exist
    """


class MissingDatabaseMetadata(Exception):
    """"""


class EntityDoesNotExist(CatalogueError):
    """"""


class AspectDoesNotExist(CatalogueError):
    """"""
