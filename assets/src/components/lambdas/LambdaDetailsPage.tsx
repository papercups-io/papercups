import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {debounce} from 'lodash';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';

import {
  notification,
  Button,
  Divider,
  Paragraph,
  Popconfirm,
  Result,
  StandardSyntaxHighlighter,
  Switch,
  Text,
  Title,
  Tooltip,
} from '../common';
import {ArrowLeftOutlined, DeleteOutlined} from '../icons';
import Spinner from '../Spinner';
import * as API from '../../api';
import {Lambda, LambdaStatus} from '../../types';
import logger from '../../logger';
import {BASE_URL} from '../../config';
import {formatRelativeTime, sleep} from '../../utils';
import {zipWithDependencies} from './support/zipper';
import {CodeSandbox, SidebarProps} from '../developers/CodeSandbox';
import EmbeddableChat from '../developers/EmbeddableChat';
import deploy from './support/deploy';

dayjs.extend(utc);

type Props = RouteComponentProps<{id: string}> & {};
type State = {
  // TODO: consolidate these into a `status` enum?
  loading: boolean;
  saving: boolean;
  deploying: boolean;
  deleting: boolean;
  //
  name: string;
  description: string;
  lambda: Lambda | null;
  personalApiKey: string | null;
  accountId: string | null;
  apiExplorerOutput: any;
  runkit: any;
};

class LambdaDetailsPage extends React.Component<Props, State> {
  papercups: any;

  state: State = {
    loading: true,
    saving: false,
    deploying: false,
    deleting: false,
    name: 'Untitled function',
    description: '',
    lambda: null,
    personalApiKey: null,
    accountId: null,
    apiExplorerOutput: null,
    runkit: null,
  };

  async componentDidMount() {
    try {
      const lambdaId = this.props.match.params.id;
      const lambda = await API.fetchLambda(lambdaId);
      const personalApiKeys = await API.fetchPersonalApiKeys();
      const key =
        personalApiKeys.length > 0
          ? personalApiKeys[personalApiKeys.length - 1]
          : null;

      this.setState({
        lambda,
        name: lambda?.name ?? 'Untitled function',
        description: lambda?.description ?? '',
        accountId: lambda?.account_id ?? null,
        personalApiKey: key ? key.value : null,
        loading: false,
      });
    } catch (err) {
      logger.error('Error loading lambda details:', err);

      this.setState({loading: false});
    }
  }

  refreshLambdaDetails = async () => {
    try {
      const lambdaId = this.props.match.params.id;
      const lambda = await API.fetchLambda(lambdaId);

      this.setState({
        lambda,
        name: lambda?.name ?? 'Untitled function',
        description: lambda?.description ?? '',
      });
    } catch (err) {
      logger.error('Error refreshing lambda details:', err);
    }
  };

  handleChangeName = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({name: e.target.value});
  };

  handleChangeDescription = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    this.setState({description: e.target.value});
  };

  getNextStatus = (lambda: Lambda, shouldActivate: boolean): LambdaStatus => {
    const {last_deployed_at: lastDeployedAt} = lambda;
    const canActivate = !!lastDeployedAt;

    if (canActivate) {
      return shouldActivate ? 'active' : 'inactive';
    } else {
      return 'pending';
    }
  };

  handleToggleState = async (isActive: boolean) => {
    const {lambda} = this.state;

    if (!lambda) {
      return;
    }

    const {id: lambdaId, status} = lambda;
    const nextStatus = this.getNextStatus(lambda, isActive);

    if (status === nextStatus) {
      return;
    }

    const result = await API.updateLambda(lambdaId, {
      status: nextStatus,
    });

    this.setState({
      lambda: result,
    });
  };

  handleSendTestMessage = () => {
    if (this.papercups) {
      this.papercups.sendNewMessage({
        body: 'Testing the message:created event!',
        metadata: {disable_webhook_events: true},
      });
    }
  };

  handleSaveLambda = async () => {
    try {
      this.setState({saving: true});

      const lambdaId = this.props.match.params.id;
      const source = await this.state.runkit.getSource();
      const lambda = await API.updateLambda(lambdaId, {
        name: this.state.name,
        description: this.state.description,
        code: source,
      });

      this.setState({
        lambda,
        name: lambda?.name ?? 'Untitled function',
        description: lambda?.description ?? '',
      });

      await sleep(1000);

      notification.success({
        message: `Function successfully saved.`,
        duration: 2, // 2 seconds
      });
    } catch (err) {
      logger.error('Error saving lambda:', err);
      await this.refreshLambdaDetails();
    } finally {
      this.setState({saving: false});
    }
  };

  debouncedSaveLambda = debounce(() => this.handleSaveLambda(), 400);

  getStatusDescription = () => {
    const {lambda} = this.state;

    if (!lambda) {
      return null;
    }

    switch (lambda.status) {
      case 'pending':
        return 'Your function cannot be activated until it has been deployed.';
      case 'active':
        return 'Your function is actively receiving webhook events.';
      case 'inactive':
      default:
        return 'Your function is inactive and will not receive webhook events.';
    }
  };

  handleDeployLambda = async () => {
    try {
      this.setState({deploying: true});

      const lambdaId = this.props.match.params.id;
      const source = await this.state.runkit.getSource();
      const blob = await zipWithDependencies(source);
      // TODO: is there any advantage to using a file vs blob?
      // const file = new File([blob], 'lambda.zip');
      const lambda = await deploy(lambdaId, blob, {
        data: {
          name: this.state.name,
          description: this.state.description,
          code: source,
        },
      });

      this.setState({lambda});

      await sleep(1000);

      notification.success({
        message: `Function successfully deployed.`,
        duration: 2, // 2 seconds
      });
    } catch (err) {
      logger.error('Error deploying lambda:', err);
      await this.refreshLambdaDetails();
    } finally {
      this.setState({deploying: false});
    }
  };

  handleDeleteLambda = async () => {
    try {
      this.setState({deleting: true});
      const lambdaId = this.props.match.params.id;

      await API.deleteLambda(lambdaId);
      await sleep(1000);

      this.props.history.push('/functions');
    } catch (err) {
      logger.error('Error deleting lambda!', err);

      this.setState({deleting: false});
    }
  };

  handleInvokeLambda = async (payload = {}) => {
    if (!this.state.lambda) {
      return;
    }

    const {id: lambdaId, code} = this.state.lambda;
    const source = await this.state.runkit.getSource();

    if (source !== code) {
      await this.handleDeployLambda();
    }

    const output = await API.invokeLambda(lambdaId, {
      event: 'message:created',
      payload,
    });

    this.setState({apiExplorerOutput: output});
  };

  handleMessageSent = (fn: (data: any) => void) => (payload = {}) => {
    if (this.state.lambda) {
      this.handleInvokeLambda(payload);
    } else {
      fn(payload);
    }
  };

  renderSidebar = ({accountId, onRunHandler}: SidebarProps) => {
    const {deploying} = this.state;

    return (
      <Flex pl={2} sx={{flex: 1, flexDirection: 'column'}}>
        <Box>
          <Button
            block
            loading={deploying}
            type="primary"
            onClick={this.handleDeployLambda}
          >
            {deploying ? 'Deploying...' : 'Deploy your code'}
          </Button>
        </Box>

        <Divider />

        <EmbeddableChat
          sx={{flex: 1, height: '100%', width: '100%'}}
          config={{
            accountId,
            primaryColor: '#1890ff',
            greeting: 'Send a message below to test your webhook handler!',
            newMessagePlaceholder: 'Send a test message...',
            baseUrl: BASE_URL,
          }}
          onChatLoaded={(papercups) => (this.papercups = papercups)}
          onMessageSent={this.handleMessageSent(onRunHandler)}
        />
      </Flex>
    );
  };

  render() {
    const {
      loading,
      deleting,
      deploying,
      lambda,
      personalApiKey,
      accountId,
      apiExplorerOutput,
    } = this.state;

    if (loading || !lambda || !accountId) {
      return (
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
      );
    }

    if (!personalApiKey) {
      return (
        <Flex my={5} sx={{justifyContent: 'center'}}>
          <Result
            status="info"
            title="An API key is required"
            subTitle={
              <Text>
                In order to set up a function, you'll need to generate an API
                key first.
              </Text>
            }
            extra={
              <Link to="/developers/personal-api-keys">
                <Button type="primary">Generate API key</Button>
              </Link>
            }
          />
        </Flex>
      );
    }

    const {
      name,
      description,
      status,
      code,
      last_deployed_at: lastDeployedAt,
    } = lambda;

    return (
      <Flex
        sx={{
          width: '100%',
          justifyContent: 'center',
          alignItems: 'center',
          flexDirection: 'column',
        }}
      >
        <Box p={4} sx={{flex: 1, width: '100%', maxWidth: 1080}}>
          <Flex
            mb={4}
            sx={{justifyContent: 'space-between', alignItems: 'center'}}
          >
            <Link to="/functions">
              <Button icon={<ArrowLeftOutlined />}>
                Back to all functions
              </Button>
            </Link>

            <Popconfirm
              title="Are you sure you want to delete this function?"
              okText="Yes"
              cancelText="No"
              placement="bottomLeft"
              onConfirm={this.handleDeleteLambda}
            >
              <Button danger loading={deleting} icon={<DeleteOutlined />}>
                Delete function
              </Button>
            </Popconfirm>
          </Flex>

          <Divider />

          <Box mb={4}>
            <Flex sx={{alignItems: 'center', justifyContent: 'space-between'}}>
              <Box sx={{flex: 1}}>
                {/* TODO: make these fields editable */}
                <Title level={4}>{name || 'Untitled function'}</Title>
                <Paragraph>{description || 'No description.'}</Paragraph>
              </Box>

              <Box>
                <Tooltip title={this.getStatusDescription}>
                  <Flex sx={{alignItems: 'center', justifyContent: 'flex-end'}}>
                    <Box mx={2}>
                      {status === 'active' ? (
                        <Text>Active</Text>
                      ) : (
                        <Text type="secondary">Inactive</Text>
                      )}
                    </Box>
                    <Switch
                      checked={status === 'active'}
                      onChange={this.handleToggleState}
                    />
                  </Flex>
                </Tooltip>

                <Box mt={1}>
                  {lastDeployedAt ? (
                    <Tooltip
                      title={dayjs(lastDeployedAt).format(
                        'dddd, MMMM D h:mm A'
                      )}
                      placement="bottom"
                    >
                      <Text style={{fontSize: 12}}>
                        Last deployed{' '}
                        {formatRelativeTime(dayjs(lastDeployedAt))}
                      </Text>
                    </Tooltip>
                  ) : (
                    <Text style={{fontSize: 12}} type="secondary">
                      Pending deployment...
                    </Text>
                  )}
                </Box>
              </Box>
            </Flex>

            <CodeSandbox
              defaultHeight={640}
              personalApiKey={personalApiKey}
              accountId={accountId}
              code={code}
              onLoad={(runkit) => this.setState({runkit})}
              onSuccess={(data) => this.setState({apiExplorerOutput: data})}
              onError={(error) => this.setState({apiExplorerOutput: error})}
              sidebar={this.renderSidebar}
              footer={({isExecuting}) => {
                return (
                  <Box
                    sx={{position: 'absolute', bottom: 0, left: 0, right: 0}}
                  >
                    <Button
                      block
                      disabled={!this.papercups}
                      loading={deploying || isExecuting}
                      onClick={this.handleSendTestMessage}
                    >
                      {deploying || isExecuting
                        ? 'Running...'
                        : 'Run with test event'}
                    </Button>
                  </Box>
                );
              }}
            />
          </Box>

          <Box>
            <Box>
              <Text strong>Output:</Text>
            </Box>
            <StandardSyntaxHighlighter
              language="json"
              style={{fontSize: 12, flex: 1, height: 240, overflow: 'scroll'}}
            >
              {apiExplorerOutput
                ? JSON.stringify(apiExplorerOutput, null, 2)
                : JSON.stringify({response: null}, null, 2)}
            </StandardSyntaxHighlighter>
          </Box>

          <Divider />
        </Box>
      </Flex>
    );
  }
}

export default LambdaDetailsPage;
