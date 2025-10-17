from .item import Item


class EventTrigger (Item):
    template = 'out/event_trigger.sql'
    src_query = 'in/event_trigger.sql'
    directory = 'event_triggers'
    schema = '.'
    function_schema: str  # from src json
    function_name: str  # from src json

    def __init__(self, src, renderer):
        super().__init__(src, renderer)

        self.function = self.get_full_name(
            self.function_schema,
            self.function_name
        )
