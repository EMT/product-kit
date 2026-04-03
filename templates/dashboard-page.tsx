import { withAuth, signOut } from '@workos-inc/authkit-nextjs'
import { Button } from '@/components/ui/button'

export default async function Dashboard() {
  const { user } = await withAuth({ ensureSignedIn: true })

  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="mx-auto max-w-sm text-center">
        <h1 className="text-2xl font-bold tracking-tight">Dashboard</h1>
        <div className="mt-4 rounded-lg border border-border bg-card p-6">
          <p className="text-sm text-muted-foreground">Signed in as</p>
          <p className="mt-1 font-medium">
            {user.firstName} {user.lastName}
          </p>
          <p className="text-sm text-muted-foreground">{user.email}</p>
        </div>
        <form
          action={async () => {
            'use server'
            await signOut()
          }}
        >
          <Button variant="outline" className="mt-4" type="submit">
            Sign out
          </Button>
        </form>
      </div>
    </div>
  )
}
