import React from 'react';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {
  colors,
  Container,
  MarkdownRenderer,
  Result,
  Text,
  Title,
} from '../common';
import * as API from '../../api';
import * as T from '../../types';
import {formatCustomerDisplayName} from '../customers/support';
import logger from '../../logger';
import Spinner from '../Spinner';

dayjs.extend(utc);

const notesByDate = (notes: Array<T.CustomerNote>) => {
  if (notes.length === 0) {
    return [];
  }

  const grouped = notes.reduce((acc, note) => {
    const date = dayjs.utc(note.created_at).format('YYYY-MM-DD');

    return {...acc, [date]: (acc[date] || []).concat(note)};
  }, {} as {[date: string]: Array<T.CustomerNote>});

  return Object.keys(grouped)
    .sort((a, b) => +new Date(b) - +new Date(a))
    .map((date) => {
      return {date, notes: grouped[date]};
    });
};

const notesByCustomer = (
  notes: Array<T.CustomerNote>
): Array<{customer: T.Customer; notes: Array<T.CustomerNote>}> => {
  if (notes.length === 0) {
    return [];
  }

  const grouped = notes.reduce((acc, note) => {
    const {customer_id: customerId} = note;

    return {...acc, [customerId]: (acc[customerId] || []).concat(note)};
  }, {} as {[customerId: string]: Array<T.CustomerNote>});

  const customersById = notes.reduce((acc, note) => {
    const {customer_id: id, customer} = note;

    if (!customer) {
      return acc;
    }

    return {...acc, [id]: customer};
  }, {} as {[id: string]: T.Customer});

  return Object.keys(grouped).map((customerId) => {
    const notes = grouped[customerId];
    const customer = customersById[customerId] as T.Customer;

    return {customer, notes};
  });
};

const NotesByCustomer = ({notes}: {notes: Array<T.CustomerNote>}) => {
  return (
    <Box>
      {notesByCustomer(notes).map(({customer, notes: customerNotes = []}) => {
        const identifier = formatCustomerDisplayName(customer);

        return (
          <Box mb={4} ml={2} key={customer.id}>
            <Box mb={1}>
              <Link to={`/customers/${customer.id}?tab=notes`}>
                <Text strong>{identifier}</Text>
              </Link>
            </Box>

            {customerNotes.map((note) => {
              const date = dayjs.utc(note.created_at).toDate();
              const ts = dayjs(date).format('ddd, MMM D h:mm A');

              return (
                <Box
                  key={note.id}
                  px={3}
                  pt={1}
                  pb={2}
                  mb={2}
                  sx={{
                    bg: colors.noteSecondary,
                    borderRadius: 2,
                  }}
                >
                  <Flex mb={1} sx={{justifyContent: 'flex-end'}}>
                    <Text type="secondary" style={{fontSize: 12}}>
                      {ts}
                    </Text>
                  </Flex>

                  <MarkdownRenderer source={note.body} />
                </Box>
              );
            })}
          </Box>
        );
      })}
    </Box>
  );
};

const NotesByDate = ({notes}: {notes: Array<T.CustomerNote>}) => {
  return (
    <Box>
      {notesByDate(notes).map(({date, notes = []}) => {
        const formatted = dayjs(date).format('MMMM DD, YYYY');

        return (
          <Box mb={5} key={date}>
            <Title level={3}>{formatted}</Title>

            <NotesByCustomer notes={notes} />
          </Box>
        );
      })}
    </Box>
  );
};

type Props = {};
type State = {
  loading: boolean;
  notes: Array<T.CustomerNote>;
};

class NotesOverview extends React.Component<Props, State> {
  state: State = {
    loading: true,
    notes: [],
  };

  async componentDidMount() {
    try {
      const notes = await API.fetchNotes();

      this.setState({notes});
    } catch (err) {
      logger.error('Error retrieving notes!', err);
    }

    this.setState({loading: false});
  }

  render() {
    const {loading, notes = []} = this.state;

    if (loading) {
      return (
        <Container>
          <Flex
            sx={{
              flex: 1,
              justifyContent: 'center',
              alignItems: 'center',
              height: '100%',
            }}
          >
            <Spinner size={40} />
          </Flex>
        </Container>
      );
    } else if (notes.length === 0) {
      return (
        <Container>
          <Result
            status="success"
            title="No notes"
            subTitle="You haven't written any customer notes yet!"
          />
        </Container>
      );
    }

    return (
      <Container>
        <Box my={4}>
          <NotesByDate notes={notes} />
        </Box>
      </Container>
    );
  }
}

export default NotesOverview;
