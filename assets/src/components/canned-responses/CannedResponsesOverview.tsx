import React from 'react';
import {Box, Flex} from 'theme-ui';
import {
  Button,
  Container,
  Input,
  Paragraph,
  Popconfirm,
  Table,
  Text,
  Title,
} from '../common';
import * as API from '../../api';
import {CannedResponse} from '../../types';
import logger from '../../logger';
import {NewCannedResponseModalButton} from './NewCannedResponseModal';

const CannedResponsesTable = ({
  loading,
  cannedResponses,
  onDeleteCannedResponse,
}: {
  loading?: boolean;
  cannedResponses: Array<CannedResponse>;
  onDeleteCannedResponse: (id: string) => void;
}) => {
  const data = cannedResponses
    .map((cannedResponse) => {
      return {key: cannedResponse.id, ...cannedResponse};
    })
    .sort((a, b) => {
      return +new Date(b.updated_at) - +new Date(a.updated_at);
    });

  const columns = [
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      render: (value: string) => {
        return <Text code>/{value}</Text>;
      },
    },
    {
      title: 'Content',
      dataIndex: 'content',
      key: 'content',
      render: (value: string) => {
        return value;
      },
    },
    {
      title: '',
      dataIndex: 'action',
      key: 'action',
      render: (value: string, record: CannedResponse) => {
        return (
          <Flex mx={-1} sx={{justifyContent: 'flex-end'}}>
            {/* 
            TODO: implement me!

            <Box mx={1}>
              <Button>Edit</Button>
            </Box> 
            */}

            <Box mx={1}>
              <Popconfirm
                title="Are you sure you want to delete this API key?"
                okText="Yes"
                cancelText="No"
                placement="topLeft"
                onConfirm={() => onDeleteCannedResponse(record.id)}
              >
                <Button danger>Delete</Button>
              </Popconfirm>
            </Box>
          </Flex>
        );
      },
    },
  ];

  return <Table loading={loading} dataSource={data} columns={columns} />;
};

type Props = {};
type State = {
  filterQuery: string;
  filteredCannedResponses: Array<CannedResponse>;
  isNewCannedResponseModalVisible: boolean;
  loading: boolean;
  cannedResponses: Array<CannedResponse>;
};

const filterCannedResponsesByQuery = (
  cannedResponses: Array<CannedResponse>,
  query?: string
): Array<CannedResponse> => {
  if (!query || !query.length) {
    return cannedResponses;
  }

  return cannedResponses.filter((cannedResponse) => {
    const {id, name, content} = cannedResponse;

    const words = [id, name, content]
      .filter((str) => str && String(str).trim().length > 0)
      .join(' ')
      .replace('_', ' ')
      .split(' ')
      .map((str) => str.toLowerCase());

    const queries = query.split(' ').map((str) => str.toLowerCase());

    return queries.every((q) => {
      return words.some((word) => word.indexOf(q) !== -1);
    });
  });
};

class CannedResponsesOverview extends React.Component<Props, State> {
  state: State = {
    filteredCannedResponses: [],
    filterQuery: '',
    isNewCannedResponseModalVisible: false,
    loading: true,
    cannedResponses: [],
  };

  async componentDidMount() {
    await this.handleRefreshCannedResponses();
  }

  handleSearchCannedResponses = (filterQuery: string) => {
    const {cannedResponses = []} = this.state;

    if (!filterQuery?.length) {
      this.setState({
        filterQuery: '',
        filteredCannedResponses: cannedResponses,
      });
    }

    this.setState({
      filterQuery,
      filteredCannedResponses: filterCannedResponsesByQuery(
        cannedResponses,
        filterQuery
      ),
    });
  };

  handleRefreshCannedResponses = async () => {
    try {
      const {filterQuery} = this.state;
      const cannedResponses = await API.fetchCannedResponses();

      this.setState({
        filteredCannedResponses: filterCannedResponsesByQuery(
          cannedResponses,
          filterQuery
        ),
        loading: false,
        cannedResponses,
      });
    } catch (err) {
      logger.error('Error loading canned responses!', err);

      this.setState({loading: false});
    }
  };

  handleDeleteCannedResponse = async (id: string) => {
    try {
      this.setState({loading: true});

      await API.deleteCannedResponse(id);
      await this.handleRefreshCannedResponses();
    } catch (err) {
      logger.error('Error deleting canned responses!', err);

      this.setState({loading: false});
    }
  };

  render() {
    const {loading, filteredCannedResponses = []} = this.state;

    return (
      <Container>
        <Flex sx={{justifyContent: 'space-between', alignItems: 'center'}}>
          <Title level={3}>Saved replies</Title>

          <NewCannedResponseModalButton
            onSuccess={this.handleRefreshCannedResponses}
          >
            New
          </NewCannedResponseModalButton>
        </Flex>

        <Box mb={4}>
          <Paragraph>
            Use saved replies to respond more quickly to common questions.
          </Paragraph>
        </Box>

        <Box mb={3}>
          <Input.Search
            placeholder="Search saved replies..."
            allowClear
            onSearch={this.handleSearchCannedResponses}
            style={{width: 400}}
          />
        </Box>

        <Box my={4}>
          <CannedResponsesTable
            loading={loading}
            cannedResponses={filteredCannedResponses}
            onDeleteCannedResponse={this.handleDeleteCannedResponse}
          />
        </Box>
      </Container>
    );
  }
}

export default CannedResponsesOverview;
