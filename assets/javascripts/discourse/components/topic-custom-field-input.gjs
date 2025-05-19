import Component from "@glimmer/component";
import { Input, Textarea } from "@ember/component";
import { on } from "@ember/modifier";
import { readOnly } from "@ember/object/computed";
import { service } from "@ember/service";
import { eq } from "truth-helpers";
import i18n from "discourse-common/helpers/i18n";

export default class TopicCustomFieldInput extends Component {
  @service siteSettings;
  @service currentUser;
  @readOnly("siteSettings.topic_heuristic_value_field_name") fieldName;
  @readOnly("siteSettings.topic_heuristic_value_field_type") fieldType;
  @readOnly("siteSettings.topic_heuristic_value_field_allowed_groups") allowedGroups;
  @readOnly("siteSettings.topic_heuristic_value_field_categories") allowedCategories;
  @readOnly("siteSettings.topic_heuristic_value_enabled") isHeuristicValueEnabled;

  get userGroups() {
    return (this.currentUser?.groups || []).map(g => g.id);
  }

  get canEditField() {
    const allowedGroups = (this.allowedGroups.length ? this.allowedGroups.split("|") : []).map(g => parseInt(g, 10)).filter(Number.isInteger);

    const userGroups = this.userGroups;
    const canEdit = userGroups.some(g => allowedGroups.includes(g));

    return canEdit;
  }

  get isAllowedCategory() {
    const allowedCategories = (this.allowedCategories.length ? this.allowedCategories.split("|") : []).map(c => parseInt(c, 10)).filter(Number.isInteger);

    const categoryId = this.args.categoryId;
    const isAllowed = allowedCategories && allowedCategories.length > 0 && categoryId && allowedCategories.includes(categoryId);
    if (!allowedCategories || allowedCategories.length === 0) {
      return false;
    }
    if (!categoryId) {
      return false;
    }
    return allowedCategories.includes(categoryId);
  }

  get canShowField() {
    return this.isHeuristicValueEnabled && this.canEditField && this.isAllowedCategory;
  }

  <template>
    {{#if this.canShowField}}
      {{#if (eq this.fieldType "boolean")}}
        <Input
          @type="checkbox"
          @checked={{@fieldValue}}
          {{on "change" (action @onChangeField value="target.checked")}}
        />
        <span>{{this.fieldName}}</span>
      {{/if}}

      {{#if (eq this.fieldType "integer")}}
        <Input
          @type="number"
          @value={{@fieldValue}}
          placeholder={{i18n
            "topic_heuristic_value.placeholder"
            field=this.fieldName
          }}
          class="topic-custom-field-input small"
          {{on "change" (action @onChangeField value="target.value")}}
        />
      {{/if}}

      {{#if (eq this.fieldType "string")}}
        <Input
          @type="text"
          @value={{@fieldValue}}
          placeholder={{i18n
            "topic_heuristic_value.placeholder"
            field=this.fieldName
          }}
          class="topic-custom-field-input large"
          {{on "change" (action @onChangeField value="target.value")}}
        />
      {{/if}}

      {{#if (eq this.fieldType "json")}}
        <Textarea
          @value={{@fieldValue}}
          {{on "change" (action @onChangeField value="target.value")}}
          placeholder={{i18n
            "topic_heuristic_value.placeholder"
            field=this.fieldName
          }}
          class="topic-custom-field-textarea"
        />
      {{/if}}
    {{/if}}
  </template>
}
