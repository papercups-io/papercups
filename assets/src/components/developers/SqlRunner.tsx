import React from 'react';
import {Box, Flex} from 'theme-ui';
import MonacoEditor from './MonacoEditor';
import {Button, Container, Checkbox, Input, notification} from '../common';
import * as API from '../../api';
import DynamicTable from './DynamicTable';
import logger from '../../logger';

const DEFAULT_SQL_VALUE = `
select u.id, u.email, count(m.id) as num_messages
  from users u
  join messages m on m.user_id = u.id
  group by u.id
  order by num_messages desc;
`;

export class SqlRunner extends React.Component<any, any> {
  monaco: any | null = null;

  state = {
    hostname: 'localhost',
    database: 'chat_api_dev',
    username: '',
    password: '',
    isSslEnabled: false,
    results: [],
    running: false,
  };

  handleEditorMounted = (editor: any) => {
    this.monaco = editor;
    this.handleRunSql();
  };

  handleImportCustomers = async () => {
    try {
      const {results = []} = this.state;
      const {data: customers} = await API.importCustomers({
        customers: results,
        dry: true,
      });

      notification.success({
        message: 'Done!',
        description: `${customers.length} customers successfully imported.`,
        duration: 10, // 10 seconds
      });
    } catch (err) {
      console.error('Failed to import customers:', err);
    }
  };

  handleRunSql = async () => {
    try {
      this.setState({running: true});

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
      this.setState({running: false});
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
          <Flex sx={{justifyContent: 'flex-end'}}>
            {/* TODO: make it possible to import contacts? */}
            <Box mr={2}>
              <Button
                disabled={this.state.running}
                onClick={this.handleImportCustomers}
              >
                Import contacts
              </Button>
            </Box>

            <Box>
              <Button
                type="primary"
                loading={this.state.running}
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

export default SqlRunner;
