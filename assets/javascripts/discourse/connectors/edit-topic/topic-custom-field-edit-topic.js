import Component from "@glimmer/component";
import { action } from "@ember/object";
import { alias } from "@ember/object/computed";
import { service } from "@ember/service";

export default class TopicCustomFieldEditTopic extends Component {
  @service siteSettings;
  @alias("siteSettings.topic_heuristic_value_field_name") fieldName;
  
  get categoryId() {
    return this.args.outletArgs.model?.categoryId;
  }

  constructor() {
    super(...arguments);
    this.fieldValue = this.args.outletArgs.model.get(this.fieldName);
  }

  @action
  onChangeField(fieldValue) {
    this.args.outletArgs.buffered.set(this.fieldName, fieldValue || 0);
  }
}
