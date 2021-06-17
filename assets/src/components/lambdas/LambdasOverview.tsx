import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {Badge, Button, Container, Paragraph, Table, Title} from '../common';
import {PlusOutlined} from '../icons';
import * as API from '../../api';
import {Lambda, LambdaStatus} from '../../types';
import logger from '../../logger';
import {NewLambdaModalButton} from './NewLambdaModal';

const LambdasTable = ({
  loading,
  lambdas,
}: {
  loading?: boolean;
  lambdas: Array<Lambda>;
}) => {
  const data = lambdas
    .map((lambda) => {
      return {key: lambda.id, ...lambda};
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
        return value;
      },
    },
    {
      title: 'Description',
      dataIndex: 'description',
      key: 'description',
      render: (value: string) => {
        return value || '--';
      },
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (status: LambdaStatus) => {
        switch (status) {
          case 'active':
            return <Badge status="processing" text="Active" />;
          case 'inactive':
            return <Badge status="error" text="Inactive" />;
          default:
            return <Badge status="default" text="Undeployed" />;
        }
      },
    },
    {
      title: '',
      dataIndex: 'action',
      key: 'action',
      render: (value: string, record: any) => {
        const {id: lambdaId} = record;

        return (
          <Link to={`/functions/${lambdaId}`}>
            <Button>Configure</Button>
          </Link>
        );
      },
    },
  ];

  return <Table loading={loading} dataSource={data} columns={columns} />;
};

type Props = RouteComponentProps<{}>;
type State = {
  loading: boolean;
  lambdas: Array<Lambda>;
};

class LambdasOverview extends React.Component<Props, State> {
  state: State = {
    loading: true,
    lambdas: [],
  };

  async componentDidMount() {
    await this.handleRefreshLambdas();
  }

  handleRefreshLambdas = async () => {
    try {
      const lambdas = await API.fetchLambdas();

      this.setState({
        loading: false,
        lambdas,
      });
    } catch (err) {
      logger.error('Error loading lambdas!', err);

      this.setState({loading: false});
    }
  };

  handleNewLambdaCreated = (lambda: Lambda) => {
    const {id: lambdaId} = lambda;

    this.props.history.push(`/functions/${lambdaId}`);
  };

  render() {
    const {loading, lambdas = []} = this.state;

    return (
      <Container>
        <Flex sx={{justifyContent: 'space-between', alignItems: 'center'}}>
          <Title level={3}>Functions</Title>

          <NewLambdaModalButton
            type="primary"
            icon={<PlusOutlined />}
            onSuccess={this.handleNewLambdaCreated}
          >
            New function
          </NewLambdaModalButton>
        </Flex>

        <Box mb={4}>
          <Paragraph>
            Create custom functions to react to webhook events and automate your
            workflow.
          </Paragraph>
        </Box>

        <Box my={4}>
          <LambdasTable loading={loading} lambdas={lambdas} />
        </Box>
      </Container>
    );
  }
}

export default LambdasOverview;
