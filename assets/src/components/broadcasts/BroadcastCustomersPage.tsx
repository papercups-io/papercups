import React from 'react';
import {Box, Flex} from 'theme-ui';
import MonacoEditor from '../developers/MonacoEditor';
import {Button, Checkbox, Input, Title, notification} from '../common';
import * as API from '../../api';
import DynamicTable from '../developers/DynamicTable';
import logger from '../../logger';
import {Broadcast, Customer} from '../../types';
import {Link, RouteComponentProps} from 'react-router-dom';
import {formatServerError, sleep} from '../../utils';
import {ArrowLeftOutlined} from '../icons';

const DEFAULT_SQL_VALUE = `
-- select u.id, u.email, count(m.id) as num_messages
--   from users u
--   join messages m on m.user_id = u.id
--   group by u.id
--   order by num_messages desc;

select u.email, p.display_name as name
  from users u join user_profiles p on u.id = p.user_id
  where u.id = 1;
`;

type Props = RouteComponentProps<{id: string}>;
type State = {
  broadcast: Broadcast | null;
  hostname: string;
  database: string;
  username: string;
  password: string;
  isSslEnabled: boolean;
  isRunning: boolean;
  results: Array<any>;
};

export class BroadcastCustomersPage extends React.Component<Props, State> {
  monaco: any | null = null;

  state: State = {
    broadcast: null,
    hostname: 'localhost',
    database: 'chat_api_dev',
    username: '',
    password: '',
    isSslEnabled: false,
    isRunning: false,
    results: [],
  };

  async componentDidMount() {
    const {id: broadcastId} = this.props.match.params;
    const broadcast = await API.fetchBroadcast(broadcastId);

    this.setState({broadcast});
  }

  handleEditorMounted = (editor: any) => {
    this.monaco = editor;
    this.handleRunSql();
  };

  handleImportCustomers = async () => {
    try {
      const {id: broadcastId} = this.props.match.params;
      const {results = []} = this.state;
      const isDryRun = false; // TODO: make this configurable
      const {data: customers} = await API.importCustomers({
        customers: results,
        dry: isDryRun,
      });

      const customerIds = customers.map((c: Customer) => c.id);
      // Separate this step from the importing data
      // TODO: add `is_subscribed` and `has_valid_email` fields to customers
      // (has_valid_email: nil indicates no check, vs false indicates invalid)
      await API.addCustomersToBroadcast(broadcastId, customerIds);

      notification.success({
        message: 'Done!',
        description: `${customers.length} customers successfully added to broadcast. Returning to broadcast...`,
        duration: 4, // 4 seconds
      });

      await sleep(1000);

      return this.props.history.push(`/broadcasts/${broadcastId}`);
    } catch (err) {
      logger.error('Failed to import customers:', formatServerError(err));
    }
  };

  handleRunSql = async () => {
    try {
      this.setState({isRunning: true});

      const {hostname, database, username, password, isSslEnabled} = this.state;
      const sql = this.monaco?.getValue();

      if (!sql) {
        return;
      }

      const results = await API.runSqlQuery({
        query: sql,
        credentials: {
          hostname,
          database,
          username,
          password,
          ssl: isSslEnabled,
        },
      });

      await sleep(1000);

      this.setState({results});
    } catch (err) {
      logger.error('Failed to run query:', formatServerError(err));
    } finally {
      this.setState({isRunning: false});
    }
  };

  render() {
    const {
      broadcast,
      hostname,
      database,
      username,
      password,
      isSslEnabled,
    } = this.state;

    if (!broadcast) {
      return null;
    }

    const {id: broadcastId, name} = broadcast;

    // TODO: make editor and query results side by side instead of top/bottom
    return (
      <Flex sx={{flex: 1, flexDirection: 'column'}}>
        <Flex
          pl={3}
          pr={4}
          py={3}
          sx={{
            bg: 'rgb(250, 250, 250)',
            justifyContent: 'space-between',
            alignItems: 'center',
            borderBottom: '1px solid rgba(0,0,0,.06)',
          }}
        >
          <Box mr={3}>
            <Link to={`/broadcasts/${broadcastId}`}>
              <Button icon={<ArrowLeftOutlined />}>Back</Button>
            </Link>
          </Box>

          <Title level={4} style={{margin: 0}}>
            Select customers for {name}
          </Title>
        </Flex>

        <Flex sx={{flex: 1}}>
          <Flex sx={{flexDirection: 'column', flex: 1}}>
            <Box p={3}>
              <Flex mb={3} mx={-2}>
                <Box mx={2} sx={{flex: 1}}>
                  <label htmlFor="hostname">Host</label>
                  <Input
                    id="hostname"
                    type="text"
                    value={hostname}
                    placeholder="localhost"
                    onChange={(e) => this.setState({hostname: e.target.value})}
                  />
                </Box>
                <Box mx={2} sx={{flex: 1}}>
                  <label htmlFor="database">Database</label>
                  <Input
                    id="database"
                    type="text"
                    value={database}
                    placeholder="papercups"
                    onChange={(e) => this.setState({database: e.target.value})}
                  />
                </Box>
              </Flex>
              <Flex mb={3} mx={-2}>
                <Box mx={2} sx={{flex: 1}}>
                  <label htmlFor="username">Username</label>
                  <Input
                    id="username"
                    type="text"
                    value={username}
                    onChange={(e) => this.setState({username: e.target.value})}
                  />
                </Box>
                <Box mx={2} sx={{flex: 2}}>
                  <label htmlFor="password">Password</label>
                  <Input
                    id="password"
                    // TODO: allow toggle password
                    type="text"
                    value={password}
                    onChange={(e) => this.setState({password: e.target.value})}
                  />
                </Box>
                <Box mx={2} py={1} sx={{width: 120, alignSelf: 'flex-end'}}>
                  <Checkbox
                    checked={isSslEnabled}
                    onChange={(e) =>
                      this.setState({isSslEnabled: e.target.checked})
                    }
                  >
                    SSL enabled
                  </Checkbox>
                </Box>
              </Flex>
            </Box>

            <Box sx={{flex: 1, position: 'relative', overflow: 'hidden'}}>
              <MonacoEditor
                height="100%"
                width="100%"
                defaultLanguage="sql"
                defaultValue={DEFAULT_SQL_VALUE}
                onMount={this.handleEditorMounted}
              />

              <Box px={2} style={{position: 'absolute', top: 12, right: 16}}>
                <Button
                  loading={this.state.isRunning}
                  onClick={this.handleRunSql}
                >
                  {this.state.isRunning ? 'Running...' : 'Run query'}
                </Button>
              </Box>
            </Box>
          </Flex>

          <Box p={4} sx={{flex: 1.2}}>
            <Flex
              mb={2}
              sx={{justifyContent: 'space-between', alignItems: 'center'}}
              style={{position: 'relative'}}
            >
              <Title level={4} style={{margin: 0}}>
                Results
              </Title>

              <Button
                type="primary"
                disabled={this.state.isRunning}
                onClick={this.handleImportCustomers}
              >
                Select customer segment
              </Button>
            </Flex>

            <DynamicTable data={this.state.results} />
          </Box>
        </Flex>
      </Flex>
    );
  }
}

export default BroadcastCustomersPage;
