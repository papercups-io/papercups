import React from 'react';
import {Box, Flex} from 'theme-ui';
import {debounce} from 'lodash';
import {ButtonProps} from 'antd/lib/button';
import * as API from '../../api';
import {Customer} from '../../types';
import {AutoComplete, Button, Modal} from '../common';
import {formatCustomerDisplayName} from './support';
import logger from '../../logger';

type Props = {
  placeholder?: string;
  value?: string;
  ignored?: Array<Customer>;
  style?: any;
  onChange: (query: string, record: any) => void;
  onSelectCustomer?: (customer: Customer) => void;
};
type State = {
  options: Customer[];
};

class SearchCustomersInput extends React.Component<Props, State> {
  state: State = {
    options: [],
  };

  handleSelectCustomer = (title: string, record: any) => {
    const {onSelectCustomer} = this.props;
    const {options = []} = this.state;
    const {key: selectedCustomerId} = record;
    const selectedCustomer = selectedCustomerId
      ? options.find((result) => result.id === selectedCustomerId)
      : null;

    if (selectedCustomer && typeof onSelectCustomer === 'function') {
      onSelectCustomer(selectedCustomer);
    }
  };

  handleSearchCustomers = (query?: string) => {
    API.fetchCustomers({q: query})
      .then(({data: customers}) => {
        this.setState({options: customers});
      })
      .catch((err) => logger.error('Error searching customers:', err));
  };

  debouncedSearchCustomers = debounce(
    (query: string) => this.handleSearchCustomers(query),
    400
  );

  render() {
    const {style = {}} = this.props;
    const {options} = this.state;

    return (
      <AutoComplete
        style={{width: '100%', ...style}}
        value={this.props.value}
        placeholder={this.props.placeholder || 'Search customers...'}
        onChange={this.props.onChange}
        onSelect={this.handleSelectCustomer}
        onSearch={this.debouncedSearchCustomers}
      >
        {options.map((customer) => {
          const {id} = customer;
          const identifier = formatCustomerDisplayName(customer);

          return (
            <AutoComplete.Option key={id} value={identifier}>
              <Flex sx={{alignItems: 'center'}}>
                <Box mr={2}>{identifier}</Box>
              </Flex>
            </AutoComplete.Option>
          );
        })}
      </AutoComplete>
    );
  }
}

export const SearchCustomersModal = ({
  visible,
  title = 'Search customers',
  onSuccess,
  onCancel,
}: {
  visible: boolean;
  title?: string;
  onSuccess: (customer: Customer) => void;
  onCancel: () => void;
}) => {
  const [query, setQuery] = React.useState('');
  const [selected, setSelectedCustomer] = React.useState<Customer | null>(null);

  const handleSuccess = () => (selected ? onSuccess(selected) : onCancel());

  return (
    <Modal
      title={title}
      visible={visible}
      width={400}
      onOk={handleSuccess}
      onCancel={onCancel}
      footer={[
        <Button key="cancel" onClick={onCancel}>
          Cancel
        </Button>,
        <Button key="submit" type="primary" onClick={handleSuccess}>
          Submit
        </Button>,
      ]}
    >
      <Box>
        <SearchCustomersInput
          value={query}
          onChange={setQuery}
          onSelectCustomer={setSelectedCustomer}
        />
      </Box>
    </Modal>
  );
};

export const SearchCustomersModalButton = ({
  modal = {},
  onSuccess,
  ...props
}: {
  modal?: {title?: string};
  onSuccess: (customer: Customer) => void;
} & ButtonProps) => {
  const [isModalOpen, setModalOpen] = React.useState(false);

  const handleOpenModal = () => setModalOpen(true);
  const handleCloseModal = () => setModalOpen(false);
  const handleSuccess = (customer: Customer) => {
    handleCloseModal();
    onSuccess(customer);
  };

  return (
    <>
      <Button type="primary" {...props} onClick={handleOpenModal} />
      <SearchCustomersModal
        title={modal.title}
        visible={isModalOpen}
        onCancel={handleCloseModal}
        onSuccess={handleSuccess}
      />
    </>
  );
};
