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
  Input,
  Paragraph,
  Result,
  StandardSyntaxHighlighter,
  Switch,
  Text,
  TextArea,
  Title,
  Tooltip,
} from '../common';
import {ArrowLeftOutlined} from '../icons';
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
  loading: boolean;
  saving: boolean;
  deploying: boolean;
  name: string;
  description: string;
  status: LambdaStatus;
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
    name: 'Untitled function',
    description: '',
    status: 'pending',
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
        status: lambda?.status ?? 'pending',
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
        status: lambda?.status ?? 'pending',
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
      status: result.status ?? 'pending',
    });
  };

  handleSendTestMessage = () => {
    if (this.papercups) {
      this.papercups.sendNewMessage({
        body: 'Testing the message:created event!',
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
        status: lambda?.status ?? 'pending',
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

      await API.updateLambda(lambdaId, {
        name: this.state.name,
        description: this.state.description,
        code: source,
      });

      const blob = await zipWithDependencies(source);
      // TODO: is there any advantage to using a file vs blob?
      // const file = new File([blob], 'lambda.zip');
      const lambda = await deploy(lambdaId, blob);

      this.setState({
        lambda,
        status: lambda?.status ?? 'pending',
      });

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

  // TODO: migrate toward always using lambda instead of runkit?
  handleMessageSent = (fn: (data: any) => void) => (payload = {}) => {
    const lambdaId = this.state.lambda?.id;

    if (lambdaId) {
      return API.invokeLambda(lambdaId, {
        event: 'message:created',
        payload,
      }).then((result) => this.setState({apiExplorerOutput: result}));
    } else {
      fn(payload);
    }
  };

  renderSidebar = ({accountId, onRunHandler}: SidebarProps) => {
    const {name, description, saving, deploying} = this.state;

    return (
      <Flex pl={2} sx={{flex: 1, flexDirection: 'column'}}>
        <Box>
          <Box mb={3}>
            <label>Name</label>
            <Input
              id="lambda_name"
              type="text"
              value={name}
              onChange={this.handleChangeName}
            />
          </Box>

          <Box mb={3}>
            <label>Description</label>
            <TextArea
              id="lambda_description"
              placeholder="Describe the purpose of this function..."
              value={description}
              onChange={this.handleChangeDescription}
            />
          </Box>

          <Flex mx={-1}>
            <Box mx={1} sx={{flex: 1}}>
              <Button block disabled={saving} onClick={this.handleSaveLambda}>
                {saving ? 'Saving...' : 'Save draft'}
              </Button>
            </Box>
            <Box mx={1} sx={{flex: 1}}>
              <Button
                block
                disabled={deploying}
                type="primary"
                onClick={this.handleDeployLambda}
              >
                {deploying ? 'Deploying...' : 'Deploy'}
              </Button>
            </Box>
          </Flex>
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
      lambda,
      personalApiKey,
      accountId,
      apiExplorerOutput,
    } = this.state;

    // TODO: does an API key need to be required?
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
          </Flex>

          <Box mb={4}>
            <Flex sx={{alignItems: 'center', justifyContent: 'space-between'}}>
              <Box sx={{flex: 1}}>
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
                      type="primary"
                      disabled={!this.papercups}
                      loading={isExecuting}
                      onClick={this.handleSendTestMessage}
                    >
                      Run with test message
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
        </Box>
      </Flex>
    );
  }
}

export default LambdaDetailsPage;
