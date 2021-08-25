import React from 'react';
import {Box, Flex} from 'theme-ui';
import MonacoEditor from '../developers/MonacoEditor';
import {Button, Container, Checkbox, Input, notification} from '../common';
import * as API from '../../api';
import DynamicTable from '../developers/DynamicTable';
import logger from '../../logger';
import {Customer} from '../../types';
import {RouteComponentProps} from 'react-router-dom';

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

  state = {
    hostname: 'localhost',
    database: 'chat_api_dev',
    username: '',
    password: '',
    isSslEnabled: false,
    isRunning: false,
    results: [],
  };

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
        description: `${customers.length} customers successfully imported.`,
        duration: 10, // 10 seconds
      });

      return customers;
    } catch (err) {
      console.error('Failed to import customers:', err);
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

      this.setState({results});
    } catch (err) {
      logger.error('Failed to run query:', err);
    } finally {
      this.setState({isRunning: false});
    }
  };

  // TODO: move to BroadcastDetailsPage
  handleSendEmails = async () => {
    try {
      const {id: broadcastId} = this.props.match.params;
      const customers = await this.handleImportCustomers();
      console.log('Sending to:', customers);
      const result = await API.sendBroadcastEmail(broadcastId);

      console.log('Sent!', result);
    } catch (err) {
      logger.error('Failed to send emails!', err);
    }
  };

  render() {
    const {hostname, database, username, password, isSslEnabled} = this.state;

    return (
      <Container>
        <Box>
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

        <Box sx={{height: 400}}>
          <MonacoEditor
            height="100%"
            width="100%"
            defaultLanguage="sql"
            defaultValue={DEFAULT_SQL_VALUE}
            onMount={this.handleEditorMounted}
          />
        </Box>

        <Box py={3}>
          <Flex sx={{justifyContent: 'space-between'}}>
            <Box mr={2}>
              <Button
                disabled={this.state.isRunning}
                onClick={this.handleImportCustomers}
              >
                Import contacts
              </Button>
            </Box>

            <Box>
              <Button
                type="primary"
                loading={this.state.isRunning}
                onClick={this.handleRunSql}
              >
                Run query
              </Button>
            </Box>
          </Flex>

          <Box my={4}>
            <DynamicTable data={this.state.results} />
          </Box>
        </Box>
      </Container>
    );
  }
}

export default BroadcastCustomersPage;
