import React from 'react';
import {Box, Flex} from 'theme-ui';
import MonacoEditor from './MonacoEditor';
import {Button, Container} from '../common';
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
    results: [],
    running: false,
  };

  handleEditorMounted = (editor: any) => {
    this.monaco = editor;
    this.handleRunSql();
  };

  handleRunSql = async () => {
    try {
      this.setState({running: true});

      const {hostname, database, username, password} = this.state;
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
          ssl: false,
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
    return (
      <Container>
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
            <Button loading={this.state.running} onClick={this.handleRunSql}>
              Run query
            </Button>
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
