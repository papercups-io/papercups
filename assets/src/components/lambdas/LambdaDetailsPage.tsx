import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {debounce} from 'lodash';
import {
  notification,
  Button,
  Divider,
  Input,
  Paragraph,
  StandardSyntaxHighlighter,
  Text,
  TextArea,
  Title,
} from '../common';
import {ArrowLeftOutlined} from '../icons';
import Spinner from '../Spinner';
import * as API from '../../api';
import {Lambda} from '../../types';
import logger from '../../logger';
import {BASE_URL} from '../../config';
import {sleep} from '../../utils';
import {CodeSandbox, SidebarProps} from '../developers/CodeSandbox';
import EmbeddableChat from '../developers/EmbeddableChat';

type Props = RouteComponentProps<{id: string}> & {};
type State = {
  loading: boolean;
  saving: boolean;
  deploying: boolean;
  name: string;
  description: string;
  lambda: Lambda | null;
  personalApiKey: string | null;
  accountId: string | null;
  apiExplorerOutput: any;
  runkit: any;
};

class LambdaDetailsPage extends React.Component<Props, State> {
  state: State = {
    loading: true,
    saving: false,
    deploying: false,
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
        personalApiKey: key ? key.value : null,
        accountId: key ? key.account_id : null,
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

  handleDeployLambda = () => {
    // TODO: implement me!
  };

  renderSidebar = ({
    accountId,
    output,
    isExecuting,
    onRunHandler,
  }: SidebarProps) => {
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
                Deploy
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
          onMessageSent={onRunHandler}
        />

        {false && (
          <Flex sx={{flex: 1, flexDirection: 'column', overflow: 'scroll'}}>
            <Box>
              <Text strong>Output:</Text>
            </Box>
            <StandardSyntaxHighlighter
              language="json"
              style={{fontSize: 12, flex: 1, minHeight: 80}}
            >
              {isExecuting
                ? JSON.stringify({status: 'Running...'}, null, 2)
                : JSON.stringify(output, null, 2)}
            </StandardSyntaxHighlighter>
          </Flex>
        )}
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
    if (loading || !lambda || !personalApiKey || !accountId) {
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
            <Title level={4}>{lambda.name || 'Untitled function'}</Title>
            <Paragraph>{lambda.description || 'No description.'}</Paragraph>

            <CodeSandbox
              defaultHeight={640}
              personalApiKey={personalApiKey}
              accountId={accountId}
              onLoad={(runkit) => this.setState({runkit})}
              onSuccess={(data) => this.setState({apiExplorerOutput: data})}
              onError={(error) => this.setState({apiExplorerOutput: error})}
              sidebar={this.renderSidebar}
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
