import React from 'react';
import {RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {Button, Container, Paragraph, Text, Title} from '../common';
import {PlusOutlined} from '../icons';
import Spinner from '../Spinner';
import * as API from '../../api';
import logger from '../../logger';
import {PersonalApiKey} from '../../types';
import PersonalApiKeysTable from '../integrations/PersonalApiKeysTable';
import NewApiKeyModal from '../integrations/NewApiKeyModal';
import ApiExplorer from './ApiExplorer';
import DynamicTable from './DynamicTable';

type Props = RouteComponentProps<{type?: string}> & {};
type State = {
  loading: boolean;
  runkit: any;
  isApiKeyModalOpen: boolean;
  personalApiKeys: Array<PersonalApiKey>;
  apiExplorerOutput: any;
};

class PersonalApiKeysPage extends React.Component<Props, State> {
  state: State = {
    loading: true,
    runkit: null,
    isApiKeyModalOpen: false,
    personalApiKeys: [],
    apiExplorerOutput: null,
  };

  async componentDidMount() {
    try {
      const personalApiKeys = await API.fetchPersonalApiKeys();

      this.setState({
        personalApiKeys,
        loading: false,
      });
    } catch (err) {
      logger.error('Error loading integrations:', err);

      this.setState({loading: false});
    }
  }

  handleAddApiKey = () => {
    this.setState({isApiKeyModalOpen: true});
  };

  handleDeleteApiKey = async (personalApiKey: PersonalApiKey) => {
    const {id: apiKeyId} = personalApiKey;

    if (!apiKeyId) {
      return;
    }

    await API.deletePersonalApiKey(apiKeyId);
    await this.refreshPersonalApiKeys();
  };

  refreshPersonalApiKeys = async () => {
    try {
      const personalApiKeys = await API.fetchPersonalApiKeys();

      this.setState({personalApiKeys});
    } catch (err) {
      logger.error('Error refreshing personal API keys:', err);
    }
  };

  handleApiKeyModalSuccess = (personalApiKey: any) => {
    this.setState({isApiKeyModalOpen: false});
    this.refreshPersonalApiKeys();
  };

  handleApiKeyModalCancel = () => {
    this.setState({isApiKeyModalOpen: false});
  };

  render() {
    const {
      loading,
      isApiKeyModalOpen,
      personalApiKeys = [],
      apiExplorerOutput,
    } = this.state;

    if (loading) {
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

    const latestApiKey = personalApiKeys[personalApiKeys.length - 1];

    return (
      <Container>
        <Box mb={5}>
          <Title level={4}>Personal API keys</Title>

          <Flex sx={{justifyContent: 'space-between', alignItems: 'baseline'}}>
            <Paragraph>
              <Text>
                Generate personal API keys to interact directly with the
                Papercups API.
              </Text>
            </Paragraph>

            <Button icon={<PlusOutlined />} onClick={this.handleAddApiKey}>
              Generate new API key
            </Button>
          </Flex>

          <Box my={4}>
            <PersonalApiKeysTable
              personalApiKeys={personalApiKeys}
              onDeleteApiKey={this.handleDeleteApiKey}
            />
          </Box>
        </Box>

        <NewApiKeyModal
          visible={isApiKeyModalOpen}
          onSuccess={this.handleApiKeyModalSuccess}
          onCancel={this.handleApiKeyModalCancel}
        />

        {/* TODO: we don't want to show this until the UX is a bit more understandable */}
        {false && latestApiKey && latestApiKey.value && (
          <Box mb={5}>
            <Title level={4}>API explorer</Title>

            <ApiExplorer
              personalApiKey={latestApiKey.value}
              onSuccess={(data) => this.setState({apiExplorerOutput: data})}
            />

            {Array.isArray(apiExplorerOutput) && (
              <Box my={4}>
                <DynamicTable data={apiExplorerOutput} />
              </Box>
            )}
          </Box>
        )}
      </Container>
    );
  }
}

export default PersonalApiKeysPage;
