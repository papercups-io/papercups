import React from 'react';
import {RouteComponentProps} from 'react-router-dom';
import {Box} from 'theme-ui';
import {Button, Input, Title} from '../common';
import * as API from '../../api';
import logger from '../../logger';

type Props = RouteComponentProps<{}>;
type State = {
  submitting: boolean;
  name: string;
  description: string;
  websiteUrl: string;
};

class CreateCompanyPage extends React.Component<Props, State> {
  state: State = {
    submitting: false,
    name: '',
    description: '',
    websiteUrl: '',
  };

  handleCreateCompany = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    try {
      const {name, description, websiteUrl} = this.state;
      const {id: companyId} = await API.createNewCompany({
        name,
        description,
        website_url: websiteUrl,
      });

      return this.props.history.push(`/companies/${companyId}`);
    } catch (err) {
      logger.error('Error creating new company:', err);
    }
  };

  render() {
    const {name, description, websiteUrl, submitting} = this.state;

    return (
      <Box p={4} sx={{maxWidth: 720}}>
        <Title level={3}>New company (beta)</Title>

        <Box my={4} sx={{maxWidth: 400}}>
          <form onSubmit={this.handleCreateCompany}>
            <Box mb={3}>
              <label htmlFor="name">Company name</label>
              <Input
                id="name"
                type="text"
                value={name}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                  this.setState({name: e.target.value})
                }
              />
            </Box>
            <Box mb={3}>
              <label htmlFor="description">Company description</label>
              <Input
                id="description"
                type="text"
                value={description}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                  this.setState({description: e.target.value})
                }
              />
            </Box>
            <Box mb={3}>
              <label htmlFor="website_url">Company website</label>
              <Input
                id="website_url"
                type="text"
                value={websiteUrl}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                  this.setState({websiteUrl: e.target.value})
                }
              />
            </Box>

            <Box my={4}>
              <Button type="primary" htmlType="submit" loading={submitting}>
                Create
              </Button>
            </Box>
          </form>
        </Box>
      </Box>
    );
  }
}

export default CreateCompanyPage;
