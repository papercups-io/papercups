import React from 'react';
import {
  BrowserRouter as Router,
  Switch,
  Route,
  Redirect,
} from 'react-router-dom';
import {useAuth} from './components/auth/AuthProvider';
import Login from './components/auth/Login';
import Register from './components/auth/Register';
import Demo from './components/demo/Demo';
import Dashboard from './components/Dashboard';
import Widget from './components/demo/Widget';
import './App.css';

const App = () => {
  const auth = useAuth();

  if (auth.loading) {
    return null; // FIXME: show loading icon
  }

  if (!auth.isAuthenticated) {
    return (
      <Router>
        <Switch>
          <Route path="/demo" component={Demo} />
          <Route path="/login" component={Login} />
          <Route path="/register/:invite" component={Register} />
          <Route path="/register" component={Register} />
          <Route path="/widget" component={Widget} />
          <Route path="*" render={() => <Redirect to="/login" />} />
        </Switch>
      </Router>
    );
  }

  return (
    <Router>
      <Switch>
        <Route path="/login" component={Login} />
        <Route path="/widget" component={Widget} />
        <Route path="/register/:invite" component={Register} />
        <Route path="/register" component={Register} />
        <Route path="/demo" component={Demo} />
        <Route path="/" component={Dashboard} />
        <Route path="*" render={() => <Redirect to="/conversations" />} />
      </Switch>
    </Router>
  );
};

export default App;
