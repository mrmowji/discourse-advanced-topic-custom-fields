import Component from "@glimmer/component";
import { action } from "@ember/object";
import { alias } from "@ember/object/computed";
import { service } from "@ember/service";

export default class TopicCustomFieldComposer extends Component {
  @service siteSettings;
  @alias("siteSettings.topic_priority_field_name") fieldName;
  @alias("args.outletArgs.model") composerModel;
  @alias("composerModel.topic") topic;

  get categoryId() {
    return this.composerModel?.categoryId;
  }

  constructor() {
    super(...arguments);

    // If the first post is being edited we need to pass our value from
    // the topic model to the composer model.
    if (
      !this.composerModel[this.fieldName] &&
      this.topic &&
      this.topic[this.fieldName]
    ) {
      this.composerModel.set(this.fieldName, this.topic[this.fieldName]);
    }

    this.fieldValue = this.composerModel.get(this.fieldName);
  }

  @action
  onChangeField(fieldValue) {
    this.composerModel.set(this.fieldName, fieldValue);
  }
}
