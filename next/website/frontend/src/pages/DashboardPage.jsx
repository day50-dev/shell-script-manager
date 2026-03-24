import { useState, useEffect } from 'react';
import { Container, Row, Col, Card, Table, Button, Badge, Tabs, Tab } from 'react-bootstrap';
import { Link } from 'react-router-dom';
import { useAuth } from '../services/AuthContext';
import { submissionsAPI, urshiesAPI } from '../services/api';
import LoadingSpinner from '../components/LoadingSpinner';
import AlertMessage from '../components/AlertMessage';
import { FiEdit, FiTrash2, FiCheck, FiX } from 'react-icons/fi';

function DashboardPage() {
  const { user, logout } = useAuth();
  const [submissions, setSubmissions] = useState([]);
  const [myUrshies, setMyUrshies] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  const [activeTab, setActiveTab] = useState('submissions');

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);
      const [subsResponse, urshiesResponse] = await Promise.all([
        submissionsAPI.getAll(),
        urshiesAPI.getAll({ limit: 50 })
      ]);
      setSubmissions(subsResponse.data);
      // Filter urshies created by this user
      const userUrshies = urshiesResponse.data.data.filter(
        u => u.created_by === user?.username
      );
      setMyUrshies(userUrshies);
      setError(null);
    } catch (err) {
      setError('Failed to load dashboard data');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteSubmission = async (id) => {
    if (!window.confirm('Are you sure you want to delete this submission?')) return;

    try {
      await submissionsAPI.delete(id);
      setSubmissions(submissions.filter(s => s.id !== id));
      setSuccess('Submission deleted');
      setTimeout(() => setSuccess(null), 3000);
    } catch (err) {
      setError('Failed to delete submission');
      console.error(err);
    }
  };

  const handleDeleteUrshie = async (id) => {
    if (!window.confirm('Are you sure you want to delete this urshie? This will also delete all submissions.')) return;

    try {
      await urshiesAPI.delete(id);
      setMyUrshies(myUrshies.filter(u => u.id !== id));
      setSuccess('Urshie deleted');
      setTimeout(() => setSuccess(null), 3000);
    } catch (err) {
      setError('Failed to delete urshie');
      console.error(err);
    }
  };

  if (loading) {
    return <LoadingSpinner text="Loading dashboard..." />;
  }

  return (
    <Container className="py-4">
      <Row className="mb-4">
        <Col>
          <div className="d-flex justify-content-between align-items-center">
            <div>
              <h2>Dashboard</h2>
              <p className="text-muted">Welcome back, {user?.displayName || user?.username}!</p>
            </div>
            <Button variant="outline-primary" onClick={logout}>
              Logout
            </Button>
          </div>
        </Col>
      </Row>

      {error && <AlertMessage variant="danger" message={error} />}
      {success && <AlertMessage variant="success" message={success} />}

      {/* User Info Card */}
      <Row className="mb-4">
        <Col>
          <Card>
            <Card.Body>
              <Row className="align-items-center">
                <Col md={2} className="text-center">
                  <img
                    src={user?.avatar || 'https://github.com/identicons/default.png'}
                    alt={user?.username}
                    className="rounded-circle"
                    width={80}
                    height={80}
                  />
                </Col>
                <Col md={10}>
                  <h4>{user?.displayName || user?.username}</h4>
                  <p className="text-muted mb-1">@{user?.username}</p>
                  {user?.email && <p className="text-muted small">{user?.email}</p>}
                </Col>
              </Row>
            </Card.Body>
          </Card>
        </Col>
      </Row>

      {/* Tabs */}
      <Tabs
        activeKey={activeTab}
        onSelect={(k) => setActiveTab(k)}
        className="mb-4"
      >
        <Tab eventKey="submissions" title={`My Submissions (${submissions.length})`}>
          {submissions.length === 0 ? (
            <Card className="text-center p-5">
              <Card.Body>
                <h5>No submissions yet</h5>
                <p className="text-muted">Submit a script URL to get started!</p>
                <Link to="/submit" className="btn btn-primary">Submit Urshie</Link>
              </Card.Body>
            </Card>
          ) : (
            <Card>
              <Card.Body>
                <Table responsive hover>
                  <thead>
                    <tr>
                      <th>Urshie</th>
                      <th>Script URL</th>
                      <th>Status</th>
                      <th>Date</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {submissions.map((sub) => (
                      <tr key={sub.id}>
                        <td>
                          <Link to={`/urshie/${sub.urshieId}`}>
                            {sub.urshieName}
                          </Link>
                        </td>
                        <td>
                          <a href={sub.scriptUrl} target="_blank" rel="noopener noreferrer" className="small">
                            {sub.scriptUrl.substring(0, 50)}...
                          </a>
                        </td>
                        <td>
                          <Badge
                            className={
                              sub.status === 'approved' ? 'bg-success' :
                              sub.status === 'rejected' ? 'bg-danger' :
                              sub.status === 'needs_review' ? 'bg-warning text-dark' :
                              'bg-secondary'
                            }
                          >
                            {sub.status}
                          </Badge>
                          {sub.needsReview && (
                            <Badge bg="info" className="ms-1">Review</Badge>
                          )}
                        </td>
                        <td>{new Date(sub.createdAt).toLocaleDateString()}</td>
                        <td>
                          <Button
                            variant="outline-danger"
                            size="sm"
                            onClick={() => handleDeleteSubmission(sub.id)}
                          >
                            <FiTrash2 />
                          </Button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </Table>
              </Card.Body>
            </Card>
          )}
        </Tab>

        <Tab eventKey="urshies" title={`My Urshies (${myUrshies.length})`}>
          {myUrshies.length === 0 ? (
            <Card className="text-center p-5">
              <Card.Body>
                <h5>No urshies created yet</h5>
                <p className="text-muted">Create an urshie to share your scripts!</p>
                <Link to="/submit" className="btn btn-primary">Create Urshie</Link>
              </Card.Body>
            </Card>
          ) : (
            <Card>
              <Card.Body>
                <Table responsive hover>
                  <thead>
                    <tr>
                      <th>Name</th>
                      <th>Description</th>
                      <th>Submissions</th>
                      <th>Created</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {myUrshies.map((urshie) => (
                      <tr key={urshie.id}>
                        <td>
                          <Link to={`/urshie/${urshie.id}`}>
                            {urshie.name}
                          </Link>
                        </td>
                        <td className="small text-muted">
                          {urshie.description?.substring(0, 50) || '-'}
                        </td>
                        <td>
                          <Badge bg="secondary">{urshie.submission_count || 0}</Badge>
                        </td>
                        <td>{new Date(urshie.created_at).toLocaleDateString()}</td>
                        <td>
                          <Link
                            to={`/urshie/${urshie.id}`}
                            className="btn btn-outline-primary btn-sm me-1"
                          >
                            View
                          </Link>
                          <Button
                            variant="outline-danger"
                            size="sm"
                            onClick={() => handleDeleteUrshie(urshie.id)}
                          >
                            <FiTrash2 />
                          </Button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </Table>
              </Card.Body>
            </Card>
          )}
        </Tab>
      </Tabs>
    </Container>
  );
}

export default DashboardPage;
