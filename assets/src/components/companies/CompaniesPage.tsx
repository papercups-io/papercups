import React from 'react';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {Button, Table, Title} from '../common';
import * as API from '../../api';
import logger from '../../logger';

const CompaniesTable = ({
  loading,
  companies,
}: {
  loading?: boolean;
  companies: Array<any>;
}) => {
  const data = companies
    .map((company) => {
      return {key: company.id, ...company};
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
      title: 'Website',
      dataIndex: 'website_url',
      key: 'website_url',
      render: (value: string) => {
        // TODO: check if valid url!
        if (value && value.length) {
          return (
            <a href={value} target="_blank" rel="noopener noreferrer">
              {value}
            </a>
          );
        } else {
          return '--';
        }
      },
    },
    {
      title: '',
      dataIndex: 'action',
      key: 'action',
      render: (value: string, record: any) => {
        const {id: companyId} = record;

        return (
          <Link to={`/companies/${companyId}`}>
            <Button>View</Button>
          </Link>
        );
      },
    },
  ];

  return <Table loading={loading} dataSource={data} columns={columns} />;
};

type Props = {};
type State = {
  loading: boolean;
  companies: Array<any>;
};

class CompaniesPage extends React.Component<Props, State> {
  state: State = {
    loading: true,
    companies: [],
  };

  async componentDidMount() {
    try {
      const companies = await API.fetchCompanies();

      this.setState({companies, loading: false});
    } catch (err) {
      logger.error('Error loading companies!', err);

      this.setState({loading: false});
    }
  }

  render() {
    const {loading, companies = []} = this.state;

    return (
      <Box p={4}>
        <Flex sx={{justifyContent: 'space-between', alignItems: 'center'}}>
          <Title level={3}>Companies (beta)</Title>
          <Link to="/companies/new">
            <Button type="primary">New company</Button>
          </Link>
        </Flex>

        <Box my={4}>
          <CompaniesTable loading={loading} companies={companies} />
        </Box>
      </Box>
    );
  }
}

export default CompaniesPage;
