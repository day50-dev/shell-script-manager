import { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import { Container, Row, Col, Card, Badge, Button, Spinner } from 'react-bootstrap';
import { urshiesAPI } from '../services/api';
import { FiCalendar, FiUser, FiLink, FiCode, FiHome } from 'react-icons/fi';

function UrshieDetailPage() {
  const { id } = useParams();
  const [urshie, setUrshie] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchUrshie();
  }, [id]);

  const fetchUrshie = async () => {
    try {
      setLoading(true);
      const response = await urshiesAPI.getById(id);
      setUrshie(response.data);
      setError(null);
    } catch (err) {
      setError('Failed to load urshie details');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const copyToClipboard = (text) => {
    navigator.clipboard.writeText(text);
  };

  if (loading) {
    return (
      <Container className="py-5">
        <div className="text-center">
          <Spinner animation="border" variant="primary" />
          <p className="mt-3 text-muted">Loading urshie...</p>
        </div>
      </Container>
    );
  }

  if (error || !urshie) {
    return (
      <Container className="py-5">
        <Row className="justify-content-center">
          <Col lg={6} className="text-center">
            <h3>Urshie Not Found</h3>
            <p className="text-muted">The urshie you're looking for doesn't exist.</p>
            <Link to="/browse" className="btn btn-primary">Browse All Urshies</Link>
          </Col>
        </Row>
      </Container>
    );
  }

  return (
    <Container className="py-4">
      {/* Breadcrumb */}
      <nav aria-label="breadcrumb" className="mb-4">
        <ol className="breadcrumb">
          <li className="breadcrumb-item"><Link to="/">Home</Link></li>
          <li className="breadcrumb-item"><Link to="/browse">Browse</Link></li>
          <li className="breadcrumb-item active">{urshie.name}</li>
        </ol>
      </nav>

      {/* Main Content */}
      <Row>
        <Col lg={8}>
          <Card className="mb-4">
            <Card.Body>
              <div className="d-flex justify-content-between align-items-start mb-3">
                <Card.Title as="h2">{urshie.name}</Card.Title>
                {urshie.tags && urshie.tags.map((tag, index) => (
                  <Badge key={index} bg="primary" className="ms-2">
                    {tag}
                  </Badge>
                ))}
              </div>

              <Card.Text className="lead">
                {urshie.description || 'No description provided'}
              </Card.Text>

              <hr />

              <div className="row g-3">
                <div className="col-md-6">
                  <div className="d-flex align-items-center">
                    <FiUser className="me-2 text-muted" />
                    <span>Created by <strong>{urshie.created_by}</strong></span>
                  </div>
                </div>
                <div className="col-md-6">
                  <div className="d-flex align-items-center">
                    <FiCalendar className="me-2 text-muted" />
                    <span>Created {new Date(urshie.created_at).toLocaleDateString()}</span>
                  </div>
                </div>
              </div>
            </Card.Body>
          </Card>

          {/* Usage */}
          <Card className="mb-4">
            <Card.Header as="h5">
              <FiCode className="me-2" />
              Usage
            </Card.Header>
            <Card.Body>
              <p>Run this urshie with:</p>
              <pre className="bg-dark text-light p-3 rounded">
                ursh {urshie.scriptUrl}
              </pre>
              <Button
                variant="outline-secondary"
                size="sm"
                onClick={() => copyToClipboard(`ursh ${urshie.scriptUrl}`)}
                className="mt-2"
              >
                Copy Command
              </Button>
            </Card.Body>
          </Card>

          {/* Submissions */}
          {urshie.submissions && urshie.submissions.length > 0 && (
            <Card>
              <Card.Header as="h5">
                Submissions ({urshie.submissions.length})
              </Card.Header>
              <Card.Body>
                {urshie.submissions.map((submission) => (
                  <Card key={submission.id} className="mb-3">
                    <Card.Body>
                      <div className="d-flex justify-content-between align-items-start">
                        <div>
                          <Card.Title as="h6">
                            <FiLink className="me-2" />
                            {submission.scriptUrl}
                          </Card.Title>
                          {submission.homepageUrl && (
                            <Card.Text className="small text-muted">
                              <FiHome className="me-1" />
                              <a href={submission.homepageUrl} target="_blank" rel="noopener noreferrer">
                                {submission.homepageUrl}
                              </a>
                            </Card.Text>
                          )}
                        </div>
                        <Badge
                          className={
                            submission.status === 'approved' ? 'bg-success' :
                            submission.status === 'rejected' ? 'bg-danger' :
                            submission.status === 'needs_review' ? 'bg-warning text-dark' :
                            'bg-secondary'
                          }
                        >
                          {submission.status}
                        </Badge>
                      </div>
                      <Card.Text className="small text-muted mb-0">
                        Submitted by {submission.submittedBy} on {new Date(submission.submittedAt).toLocaleDateString()}
                      </Card.Text>
                    </Card.Body>
                  </Card>
                ))}
              </Card.Body>
            </Card>
          )}
        </Col>

        {/* Sidebar */}
        <Col lg={4}>
          <Card className="mb-4">
            <Card.Header as="h5">Quick Links</Card.Header>
            <Card.Body>
              {urshie.homepageUrl && (
                <div className="mb-3">
                  <a
                    href={urshie.homepageUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="btn btn-outline-primary w-100"
                  >
                    <FiHome className="me-2" />
                    Visit Homepage
                  </a>
                </div>
              )}
              <a
                href={urshie.scriptUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="btn btn-outline-secondary w-100"
              >
                <FiCode className="me-2" />
                View Script
              </a>
            </Card.Body>
          </Card>

          <Card>
            <Card.Header as="h5">Stats</Card.Header>
            <Card.Body>
              <div className="d-flex justify-content-between mb-2">
                <span>Submissions:</span>
                <strong>{urshie.submission_count || 0}</strong>
              </div>
              <div className="d-flex justify-content-between">
                <span>Last Updated:</span>
                <strong>
                  {urshie.last_submitted
                    ? new Date(urshie.last_submitted).toLocaleDateString()
                    : 'N/A'}
                </strong>
              </div>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  );
}

export default UrshieDetailPage;
