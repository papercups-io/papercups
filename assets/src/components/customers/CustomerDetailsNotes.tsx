import React from 'react';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {Box, Flex} from 'theme-ui';

import {
  colors,
  Button,
  Divider,
  Empty,
  MarkdownRenderer,
  Popconfirm,
  Text,
} from '../common';
import {DeleteOutlined} from '../icons';
import {CustomerNote, User} from '../../types';
import {formatRelativeTime} from '../../utils';
import * as API from '../../api';
import CustomerDetailsNewNoteInput from './CustomerDetailsNewNoteInput';
import logger from '../../logger';
import Spinner from '../Spinner';

dayjs.extend(utc);

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
    const {isLoading, customerNotes = []} = this.state;

    return (
      <Box p={3}>
        <CustomerDetailsNewNoteInput
          customerId={customerId}
          onCreateNote={this.handleCreateNote}
        />

        <Divider />

        {isLoading && customerNotes.length === 0 && (
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
        )}
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

const formatNoteAuthor = (author?: User): string => {
  if (!author) {
    return '';
  }

  const {display_name: displayName, full_name: fullName, email} = author;
  const authorName = displayName || fullName;

  return !!authorName ? `${authorName} (${email})` : email;
};

const CustomerDetailNote = ({
  note,
  onDeleteNote,
}: {
  note: CustomerNote;
  onDeleteNote: (note: CustomerNote) => void;
}) => {
  const {created_at: createdAt, author} = note;
  const formattedAuthor = formatNoteAuthor(author);
  const formattedTimestamp = formatRelativeTime(dayjs.utc(createdAt));

  return (
    <Box
      mb={2}
      sx={{
        bg: colors.noteSecondary,
        borderRadius: 2,
      }}
    >
      <Flex>
        <Box px={3} pt={3} sx={{flex: 1}}>
          <MarkdownRenderer source={note.body} />
        </Box>

        <Popconfirm
          title="Delete this note?"
          okText="Delete"
          cancelText="Cancel"
          placement="left"
          onConfirm={() => onDeleteNote(note)}
        >
          <Button type="link" danger icon={<DeleteOutlined />}></Button>
        </Popconfirm>
      </Flex>

      <Box px={3} pb={2}>
        <Text type="secondary">
          {formattedAuthor} — {formattedTimestamp}
        </Text>
      </Box>
    </Box>
  );
};

export default CustomerDetailsNotes;
