import React from 'react';
import {ComponentStory, ComponentMeta} from '@storybook/react';

import {Login} from './Login';
import {MemoryRouter} from 'react-router-dom';

export default {
  title: 'Example/Login',
  component: Login,
} as ComponentMeta<typeof Login>;

const Template: ComponentStory<typeof Login> = (args) => (
  <MemoryRouter>
    <Login {...args} />
  </MemoryRouter>
);

export const Default = Template.bind({});

Default.args = {
  query: '',
  onSubmit: () => Promise.resolve(),
};
