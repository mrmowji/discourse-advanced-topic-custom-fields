import Component from "@glimmer/component";
import { inject as controller } from "@ember/controller";
import { alias } from "@ember/object/computed";
import { service } from "@ember/service";

export default class TopicCustomFieldTopicTitle extends Component {
  @service siteSettings;
  @controller topic;
  @alias("siteSettings.topic_priority_field_name") fieldName;

  get fieldValue() {
    return this.args.outletArgs.model.get(this.fieldName);
  }

  get categoryId() {
    return this.args.outletArgs.model?.category_id;
  }

  get isAllowedCategory() {
    return this.categoryId && this.siteSettings.topic_priority_field_categories?.split("|").map(c => parseInt(c, 10)).includes(this.categoryId);
  }
}
