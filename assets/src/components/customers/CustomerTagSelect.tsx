import React from 'react';
import * as API from '../../api';
import {Tag} from '../../types';
import {Select} from '../common';

const {Option} = Select;

type Props = {
  onChange: (selectedTagIds: string[]) => void;
  placeholder?: string;
  style?: React.CSSProperties;
};
type State = {tags: Tag[]};

class CustomerTagSelect extends React.Component<Props, State> {
  state: State = {
    tags: [],
  };

  async componentDidMount() {
    const tags = await API.fetchAllTags();
    this.setState({tags});
  }

  render() {
    const {onChange, placeholder = 'Select tags', style = {}} = this.props;
    const {tags} = this.state;
    return (
      <Select
        allowClear
        mode="multiple"
        onChange={onChange}
        placeholder={placeholder}
        style={style}
      >
        {tags.map((tag) => (
          <Option key={tag.id} value={tag.id}>
            {tag.name}
          </Option>
        ))}
      </Select>
    );
  }
}

export default CustomerTagSelect;
