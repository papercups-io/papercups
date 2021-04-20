import React from 'react';
import dayjs from 'dayjs';
import {Box, Flex} from 'theme-ui';

import {colors, Divider, Empty, Popconfirm, Text} from '../common';
import {CustomerNote} from '../../types';
import {formatRelativeTime} from '../../utils';
import * as API from '../../api';
import CustomerDetailsNewNoteInput from './CustomerDetailsNewNoteInput';
import logger from '../../logger';
import Spinner from '../Spinner';

type Props = {customerId: string};
type State = {
  customerNotes: CustomerNote[];
  isLoading: boolean;
};

class CustomerDetailsNotes extends React.Component<Props, State> {
  state: State = {
    customerNotes: [],
    isLoading: true,
  };

  componentDidMount() {
    this.fetchCustomerNotes();
  }

  fetchCustomerNotes = async () => {
    this.setState({isLoading: true});

    try {
      const customerNotes = await API.fetchCustomerNotes(this.props.customerId);
      this.setState({customerNotes, isLoading: false});
    } catch (error) {
      logger.error('Failed to fetch cutsomer notes', error);
    }
  };

  handleCreateNote = () => {
    this.fetchCustomerNotes();
  };

  handleDeleteNote = async (note: CustomerNote) => {
    try {
      await API.deleteCustomerNote(note.id);
      await this.fetchCustomerNotes();
    } catch (error) {
      logger.error('Failed to delete customer note', error);
    }
  };

  render() {
    const {customerId} = this.props;
    const {isLoading, customerNotes} = this.state;

    if (isLoading) {
      return (
        <Flex
          p={4}
          sx={{
            flex: 1,
            justifyContent: 'center',
            alignItems: 'center',
            height: '100%',
          }}
        >
          <Spinner size={40} />
        </Flex>
      );
    }

    return (
      <Box p={3}>
        <CustomerDetailsNewNoteInput
          customerId={customerId}
          onCreateNote={this.handleCreateNote}
        />

        <Divider dashed />

        {customerNotes.length === 0 ? (
          <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} />
        ) : (
          <Box>
            {customerNotes
              .sort((a: CustomerNote, b: CustomerNote) => {
                return +new Date(b.created_at) - +new Date(a.created_at);
              })
              .map((note) => (
                <CustomerDetailNote
                  key={note.id}
                  note={note}
                  onDeleteNote={this.handleDeleteNote}
                />
              ))}
          </Box>
        )}
      </Box>
    );
  }
}

const CustomerDetailNote = ({
  note,
  onDeleteNote,
}: {
  note: CustomerNote;
  onDeleteNote: (note: CustomerNote) => void;
}) => {
  const {created_at: createdAt} = note;
  let authorIdentifier;

  if (note.author) {
    const {display_name: displayName, full_name: fullName, email} = note.author;
    const authorName = displayName || fullName;
    authorIdentifier = !!authorName ? `${authorName} · ${email}` : email;
  }

  return (
    <Popconfirm
      title="Delete this note?"
      okText="Delete"
      cancelText="Cancel"
      placement="left"
      onConfirm={() => onDeleteNote(note)}
    >
      <Box
        py={2}
        px={3}
        mb={2}
        sx={{
          bg: colors.note,
          borderRadius: 2,
          cursor: 'pointer',
        }}
      >
        <Box mb={3} sx={{whiteSpace: 'break-spaces'}}>
          {note.body}
        </Box>
        <Flex sx={{justifyContent: 'space-between'}}>
          <Text type="secondary">{authorIdentifier}</Text>
          <Text type="secondary">{formatRelativeTime(dayjs(createdAt))}</Text>
        </Flex>
      </Box>
    </Popconfirm>
  );
};

export default CustomerDetailsNotes;
