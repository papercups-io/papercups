import React from 'react';
import * as API from '../../api';
import {Tag} from '../../types';
import {Select} from '../common';

const filterSelectOption = (input: string, option: any) => {
  const label = option && option.label ? String(option.label) : '';
  const sanitized = label.toLowerCase().replace(/_/, ' ');

  return sanitized.indexOf(input.toLowerCase()) >= 0;
};

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
        filterOption={filterSelectOption}
        placeholder={placeholder}
        style={style}
        options={tags.map((tag) => {
          return {value: tag.id, label: tag.name};
        })}
      />
    );
  }
}

export default CustomerTagSelect;
