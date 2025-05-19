import SortableColumn from "discourse/components/topic-list/header/sortable-column";
import { alias } from "@ember/object/computed";
import { withPluginApi } from "discourse/lib/plugin-api";
import discourseComputed from "discourse-common/utils/decorators";

const CustomFieldHeaderCell = <template>
  <SortableColumn
    @sortable={{@sortable}}
    @number="false"
    @order="heuristic_value"
    @activeOrder={{@activeOrder}}
    @changeSort={{@changeSort}}
    @ascending={{@ascending}}
    @name="topic_heuristic_value.title"
  />
</template>;

const CustomFieldItemCell = <template>
  <td class="custom-field topic-list-data">
    {{@topic.heuristic_value}}
  </td>
</template>;

export default {
  name: "topic-custom-field-intializer",
  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");
    const fieldName = siteSettings.topic_heuristic_value_field_name;

    withPluginApi("1.37.3", (api) => {
      api.serializeOnCreate(fieldName);
      api.serializeToDraft(fieldName);
      api.serializeToTopic(fieldName, `topic.${fieldName}`);

      api.modifyClass("component:topic-list-item", {
        pluginId: "topic-custom-field",
        customFieldName: fieldName,
        customFieldValue: alias(`topic.${fieldName}`),

        showCustomField: discourseComputed("customFieldValue", function (value) {
          return value !== null && value !== undefined;
        }),
      });
    });

    withPluginApi("2.1.0", (api) => {
      api.registerValueTransformer(
        "topic-list-columns",
        ({ value, context }) => {
          if (!siteSettings.topic_heuristic_value_enabled) return;

          const allowedCategories = siteSettings.topic_heuristic_value_field_categories;
          // AI: context.category can be an object or an ID
          const categoryId = context?.category?.id || context?.category;

          if (
            (categoryId && allowedCategories?.split("|").map(c => parseInt(c, 10)).includes(categoryId))
          ) {
            value.add(
              fieldName,
              { header: CustomFieldHeaderCell, item: CustomFieldItemCell },
            );
          }
        }
      );
    });
  },
};
